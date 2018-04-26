unit Unit1;
     
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls , Math, OpenGL, ComCtrls, Menus, Grids, jpeg,
  ToolWin, Buttons, Spin, ValEdit;

type
  Tfmain = class(TForm)
    GroupBox1: TGroupBox;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    Label7: TLabel;
    StatusBar1: TStatusBar;
    CheckBox1: TCheckBox;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    About1: TMenuItem;
    OpenMap1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    Panel3: TPanel;
    fscreen: TImage;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    NewMap1: TMenuItem;
    SaveMap1: TMenuItem;
    SaveMapAs1: TMenuItem;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure fscreenClick(Sender: TObject);
    procedure fscreenMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CheckBox1Click(Sender: TObject);
    procedure fscreenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetScreenResolution(const width, height, colorDepth : integer);
  end;


const
  MAX_SURFACES = 1000;
  MAX_TEX = 10;


  type tmap = record
    total_surf : integer;
  end;

  type tstar = record
    x, y : integer;
  end;

  type t3vertex = record
    x, y, z : real;
  end;

  type t2vertex = record
    x, y : real;
    distance_vertex_intersection : real;
    distance_vertex_camera : real;
    distance_camera_intersection : real;
    angle : real;
  end;

  type tsurface = record
    _3vertices : array[0..15] of t3vertex;
    _2vertices : array[0..15] of t2vertex;
    color : tcolor;
    solid : boolean;
    vertical : boolean;
  end;




  type tcamera = record
    x, y, z : real;
    r : real;
    phi, theta, eta : real; // eta is the angle of rotation around the view vector
    vx, vy, vz : real;
  end;

  type tplayer = record
    name : string;
    hp : integer;
    x, y, z : real;
    xx, yy : real;
  end;

  type ttool = (ttoolline, ttoolsurface, ttool_block);






var
  fmain: Tfmain;
  inter_x, inter_y, inter_z : real;
  tool : ttool;
  clicked : boolean;
  height1, height2 : real;
  vertex_index : integer;
  surfaces : array[0..MAX_SURFACES] of tsurface;
  player : tplayer;
  surface_index : integer;
  
  camera : tcamera;
  screen, final_screen : tbitmap;
  mapscreen : tbitmap;

  SCREEN_WIDTH : real;
  SCREEN_HEIGHT : real;
  final_screen_width : real;
  final_screen_height : real;
  DISTANCE_CAMERA_SCREEN_SIDE : real;
  DISTANCE_CAMERA_SCREEN_CENTRE : real;
  ANGLE_OF_VISION : real;
  HALF_ANGLE_OF_VISION : real;
  MAX_VIEWING_DISTANCE : real;
  SPEED : real;



  uux, uuy, uuz : real;
  nnx, nny, nnz : real;

  oldx, oldy : integer;
  mouse_counter : integer;

  oldwidth, oldheight : integer;

  clock : longint;

  // screen mouse variables
  coordx, coordy : integer;
  mouse_distance, mouse_angle : real;
  distance_x, distance_y : real;
implementation

uses tools, map;

{$R *.dfm}

procedure tfmain.SetScreenResolution(const width, height, colorDepth : integer);
var
	mode:TDevMode;
begin
	zeroMemory(@mode, sizeof(TDevMode));
	mode.dmSize := sizeof(TDevMode);
  	mode.dmPelsWidth := width;
  	mode.dmPelsHeight := height;
  	mode.dmBitsPerPel := colorDepth;
  	mode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
  	ChangeDisplaySettings(mode, 0);
end;



procedure Tfmain.FormCreate(Sender: TObject);
var
  i, j, k : integer;
begin
  doublebuffered := true;

  DISTANCE_CAMERA_SCREEN_CENTRE := 25;
  ANGLE_OF_VISION := pi/2;
  SPEED := 10;
  MAX_VIEWING_DISTANCE := 10000;

  screen := tbitmap.create;
  screen.width := fscreen.Width;
  screen.height := fscreen.height;
  screen.canvas.Pen.color := clblack;
  screen.Canvas.Brush.color := clteal;

  final_screen := tbitmap.create;
  final_screen.canvas.Pen.color := clblack;
  final_screen.Canvas.Brush.color := clteal;

  mapscreen := tbitmap.create;
  mapscreen.width := 300;
  mapscreen.height := 300;
  mapscreen.canvas.Pen.color := clwhite;
  mapscreen.Canvas.Brush.color := clblack;

  camera.phi := pi/2;
  camera.theta := 0;
  camera.y := -100;
  camera.x := -100;
  camera.z := 100;
   

  randomize;
  surfaces[0].color := rgb(random(256), 0, 0);
  surfaces[0]._3vertices[0].x := 0;
  surfaces[0]._3vertices[0].y := 0;
  surfaces[0]._3vertices[0].z := 0;
  surfaces[0]._3vertices[1].x := 1000;
  surfaces[0]._3vertices[1].y := 0;
  surfaces[0]._3vertices[1].z := 0;
  surfaces[0]._3vertices[2].x := 1000;
  surfaces[0]._3vertices[2].y := 1000;
  surfaces[0]._3vertices[2].z := 0;
  surfaces[0]._3vertices[3].x := 0;
  surfaces[0]._3vertices[3].y := 1000;
  surfaces[0]._3vertices[3].z := 0;

 

end;

procedure read_keyboard();
begin
  {if getkeystate(vk_space) < 0 then
  begin
    if camera.z <= 80 then
      camera.yveloc := 12;
  end;    }


  if getkeystate($57) < 0 then
    begin
      camera.x := camera.x + SPEED * cos(camera.theta);
      camera.y := camera.y + SPEED * sin(camera.theta);
      camera.z := camera.z + SPEED * cos(camera.phi);
    end;
    if getkeystate($53) < 0 then
    begin
      camera.x := camera.x - SPEED * cos(camera.theta);
      camera.y := camera.y - SPEED * sin(camera.theta);
      camera.z := camera.z - SPEED * cos(camera.phi);
    end;
    if (getkeystate(VK_DOWN) < 0) then
    begin
      //if camera.phi + 0.01 <= pi then
        camera.phi := camera.phi + 0.025;
    end;
    if (getkeystate(VK_UP) < 0) then
    begin
      //if camera.phi - 0.01 >= 0 then
        camera.phi := camera.phi - 0.025;
    end;
    if getkeystate(VK_SHIFT) < 0 then
    begin
      if getkeystate(VK_LEFT) < 0 then
      begin
        camera.eta := camera.eta - 0.025;
      end;
      if getkeystate(VK_RIGHT) < 0 then
      begin
        camera.eta := camera.eta + 0.025;
      end;
    end
    else
    begin
      if getkeystate(VK_LEFT) < 0 then
      begin
        camera.theta := camera.theta - 0.025;
      end;
      if getkeystate(VK_RIGHT) < 0 then
      begin
        camera.theta := camera.theta + 0.025;
      end;
    end;

    if getkeystate($41) < 0 then
    begin
      camera.x := camera.x - SPEED * nnx;
      camera.y := camera.y - SPEED * nny;
      camera.z := camera.z - SPEED * nnz;
    end;
    if getkeystate($44) < 0 then
    begin
      camera.x := camera.x + SPEED * nnx;
      camera.y := camera.y + SPEED * nny;
      camera.z := camera.z + SPEED * nnz;
    end;
  
    if getkeystate($51) < 0 then
    begin
      camera.x := camera.x - SPEED * uux;
      camera.y := camera.y - SPEED * uuy;
      camera.z := camera.z - SPEED * uuz;
    end;
    if getkeystate($45) < 0 then
    begin
      camera.x := camera.x + SPEED * uux;
      camera.y := camera.y + SPEED * uuy;
      camera.z := camera.z + SPEED * uuz;
    end;

  SPEED := ftools.trackbar2.position;
  DISTANCE_CAMERA_SCREEN_CENTRE := ftools.trackbar1.position;
  ANGLE_OF_VISION := (ftools.trackbar3.position / 360) * 2 * pi;
  HALF_ANGLE_OF_VISION := ANGLE_OF_VISION / 2;
  MAX_VIEWING_DISTANCE := ftools.trackbar4.position;
  SCREEN_WIDTH := 2 * DISTANCE_CAMERA_SCREEN_CENTRE * abs( tan(HALF_ANGLE_OF_VISION) );
  SCREEN_HEIGHT := 2 * DISTANCE_CAMERA_SCREEN_CENTRE * abs( tan(HALF_ANGLE_OF_VISION) );
  DISTANCE_CAMERA_SCREEN_SIDE := DISTANCE_CAMERA_SCREEN_CENTRE / abs( cos(HALF_ANGLE_OF_VISION) );
end;

procedure draw_maps();
var
  i, j : integer;
begin
    mapscreen.canvas.Brush.color := clblack;
    mapscreen.canvas.FillRect(rect(0, 0, mapscreen.width, mapscreen.height));
    mapscreen.canvas.Pen.color := clwhite;

    // draw field of view lines
    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x), mapscreen.height div 2 - round(camera.y)),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta - HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta - HALF_ANGLE_OF_VISION)))
      ]);

    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x), mapscreen.height div 2 - round(camera.y)),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION)))
      ]);


    // draw projection plane
    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta - HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta - HALF_ANGLE_OF_VISION))),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION)))
      ]);


    // draw max viewing distance plane
    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION))),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION) + cos(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION) +
        sin(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)))
      ]);
    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta - HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta - HALF_ANGLE_OF_VISION))),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta - HALF_ANGLE_OF_VISION) + cos(camera.theta-HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta - HALF_ANGLE_OF_VISION) +
        sin(camera.theta-HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)))
      ]);
      mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION))),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION) + cos(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION) +
        sin(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)))
      ]);
    mapscreen.canvas.Polygon([
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta + HALF_ANGLE_OF_VISION) + cos(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta + HALF_ANGLE_OF_VISION) +
        sin(camera.theta+HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION))),
      point(mapscreen.width div 2 + round(camera.x + DISTANCE_CAMERA_SCREEN_SIDE * cos(camera.theta - HALF_ANGLE_OF_VISION) + cos(camera.theta-HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)),
        mapscreen.height div 2 - round(camera.y + DISTANCE_CAMERA_SCREEN_SIDE * sin(camera.theta - HALF_ANGLE_OF_VISION) +
        sin(camera.theta-HALF_ANGLE_OF_VISION)*MAX_VIEWING_DISTANCE/cos(HALF_ANGLE_OF_VISION)))
      ]);





    


    // draw xy axis
    mapscreen.canvas.Pen.color := clblue;
    mapscreen.canvas.MoveTo(0, mapscreen.height div 2);
    mapscreen.canvas.lineTo(mapscreen.width, mapscreen.height div 2);
    mapscreen.canvas.MoveTo(mapscreen.width div 2, 0);
    mapscreen.canvas.lineTo(mapscreen.width div 2, mapscreen.height);
  // draw mapscreen objects
    mapscreen.canvas.Pen.color := clwhite;
end;

procedure update_info();
begin
  fmain.labelededit1.Text := floattostr(round(camera.x)) + ', ' + floattostr(round(camera.y)) + ', ' + floattostr(round(camera.z)) + ', ' + floattostr(round(sqrt(camera.x*camera.x + camera.y*camera.y + camera.z*camera.z)));
  fmain.labelededit2.Text := 'Theta: ' + inttostr(round(360 * camera.theta / (2*pi)) mod 360) + ', Phi: ' + inttostr(round(360 * camera.phi / (2*pi)) mod 360) + ', Eta: ' + inttostr(round(360 * camera.eta / (2*pi)) mod 360);

  fmain.labelededit3.Text := floattostr(round(camera.vx)) + ', ' + floattostr(round(camera.vy)) + ', ' + floattostr(round(camera.vz));

  fmain.labelededit4.Text := floattostr(round(1000*uux)) + ', ' + floattostr(round(1000*uuy)) + ', ' + floattostr(round(1000*uuz));
  fmain.labelededit5.Text := floattostr(round(1000*nnx)) + ', ' + floattostr(round(1000*nny)) + ', ' + floattostr(round(1000*nnz));

end;

function dot(a, b, c, x, y, z : real) : real;
begin
  result := a * x + b * y + c * z;
end;

function length(x, y, z : real) : real;
begin
  result := sqrt(x*x + y*y + z*z);
end;

procedure draw_perspective();
var
  i, j, k, v : integer;

  rx, ry, rz : real;
  bx, by, bz : real;

  len : real; // vector length

  ux, uy, uz : real; // plane span 1
  nx, ny, nz : real; // plane span 2

  t : real;
  ax, ay, az : real;
  verx, very, verz : real;
  cx, cy, cz : real;
  
  centre_to_inter_x, centre_to_inter_y, centre_to_inter_z : real;
  xx, yy : real;
  vertex_anglex, vertex_angley : real;
  cosine : real;
  angle : real;

  distance_vertex_intersection : real;
  distance_camera_intersection : real;
  distance_vertex_camera : real;

  within_bounds : boolean;

  vert1, vert2, hor1, hor2 : real;
begin
//stretchblt(screen.canvas.Handle, 0,0,screen.width,screen.Height, fmain.image1.Canvas.Handle,0,0,fmain.Image1.width,fmain.Image1.Height, srccopy);
//screen.canvas.Draw(0,0,fmain.image1.Picture.Bitmap);
  screen.canvas.fillrect(rect(0, 0, screen.width, screen.height));
// draw stars
{  for i := 0 to MAX_STARS - 1 do
  begin
    screen.canvas.Pixels[round(stars[i].x), round(stars[i].y)] := clwhite;
  end;      }




{

        n
        n
        n
        n
        n
          u u u u u
       v
      v
     v
    v

}



  // lets find the vision angle vector
  camera.vx := DISTANCE_CAMERA_SCREEN_CENTRE * sin(camera.phi) * cos(camera.theta);
  camera.vy := DISTANCE_CAMERA_SCREEN_CENTRE * sin(camera.phi) * sin(camera.theta);
  camera.vz := DISTANCE_CAMERA_SCREEN_CENTRE * cos(camera.phi);

  // now lets calculate the first perpendicular vector (u) by doing a dot product with the view vector
  // for this vector we want the Z component to be 0 so that it is parallel top the ground.
  // the Y component can be anything, and then we find the X component
  // we will use this vector and the one perpendicular to it as a building set for the actual vectors we will use
  // as the vectors we use to calculate distances inside the vision plane
  uz := 0;
  if cos(camera.theta) >= 0 then
  begin
    uy := 1;
    ux := -camera.vy/camera.vx;
  end
  else
  begin
    uy := -1;
    ux := camera.vy/camera.vx;
  end;
  // and convert it into a unit vector
  len := length(ux, uy, uz);
  ux := ux / len;
  uy := uy / len;
  uz := uz / len;

  // now calculate the second perpendicular to the view vector by taking the cross product
  nx := uz*camera.vy - uy*camera.vz;
  ny := ux*camera.vz - uz*camera.vx;
  nz := uy*camera.vx - ux*camera.vy;
  // and convert it into a unit vector
  len := length(nx, ny, nz);
  nx := nx/len;
  ny := ny/len;
  nz := nz/len;

  // we now build the actual vectors we use inside the plane by using the previous two vectors as building vectors
  // we do this so that we can freely choose 2 vectors based on the angle eta.
  uux := ux * cos(camera.eta) + nx * sin(camera.eta);
  uuy := uy * cos(camera.eta) + ny * sin(camera.eta);
  uuz := uz * cos(camera.eta) + nz * sin(camera.eta);
  nnx := ux * cos(camera.eta + pi/2) + nx * sin(camera.eta + pi/2);
  nny := uy * cos(camera.eta + pi/2) + ny * sin(camera.eta + pi/2);
  nnz := uz * cos(camera.eta + pi/2) + nz * sin(camera.eta + pi/2);

  // camera coordinates
  cx := camera.x;
  cy := camera.y;
  cz := camera.z;

  // vision plane centre
  ax := cx + camera.vx;
  ay := cy + camera.vy;
  az := cz + camera.vz;
      
  // now we find the intersection of each vertex with the vision plane
      for k := 0 to MAX_SURFACES - 1 do
      begin
        for v := 0 to 3 do
        begin
          // current vertex coordinates
          verx := surfaces[k]._3vertices[v].x;
          very := surfaces[k]._3vertices[v].y;
          verz := surfaces[k]._3vertices[v].z;

          // parameter for line from camera to current vertex
          t := ( camera.vx*sin(camera.phi)*cos(camera.theta) + camera.vy*sin(camera.phi)*sin(camera.theta) + camera.vz*cos(camera.phi) )
               / ( (verx - cx) * sin(camera.phi)*cos(camera.theta) + (very - cy)*sin(camera.phi)*sin(camera.theta) + (verz - cz)*cos(camera.phi) );

          // this is the intersection point on the plane
          inter_x := cx + (verx - cx) * t;
          inter_y := cy + (very - cy) * t;
          inter_z := cz + (verz - cz) * t;

          // this is a vector from the plane centre to the intersection point on the plane
          centre_to_inter_x := inter_x - ax;
          centre_to_inter_y := inter_y - ay;
          centre_to_inter_z := inter_z - az;

          // now we need to find the lengths of both components of the inside vector
          // and check if they are within the bounds of the plane
          // to do this we take the dot product between the unit vectors which span the vision plane
          //and the vectors from the plane centre to the intersection
          xx := dot(centre_to_inter_x, centre_to_inter_y, centre_to_inter_z, uux, uuy, uuz);
          yy := dot(centre_to_inter_x, centre_to_inter_y, centre_to_inter_z, nnx, nny, nnz);

          // distances
          distance_vertex_intersection := length(verx - inter_x, very - inter_y, verz - inter_z);
          distance_camera_intersection := length(inter_x - cx, inter_y - cy, inter_z - cz);
          distance_vertex_camera := length(verx - cx, very - cy, verz - cz);
          // cosine between viewing vector and vertex vector to check if the vertex is within field of view (a circle)
          cosine := dot(camera.vx, camera.vy, camera.vz, verx-cx, very-cy, verz-cz) / (length(camera.vx, camera.vy, camera.vz) * length(verx-cx, very-cy, verz-cz));
          angle := arccos(cosine);

          surfaces[k]._2vertices[v].x := xx / (SCREEN_WIDTH / 2);
          surfaces[k]._2vertices[v].y := yy / (SCREEN_HEIGHT / 2);
          surfaces[k]._2vertices[v].distance_vertex_intersection := distance_vertex_intersection;
          surfaces[k]._2vertices[v].distance_camera_intersection := distance_camera_intersection;
          surfaces[k]._2vertices[v].distance_vertex_camera := distance_vertex_camera;
          surfaces[k]._2vertices[v].angle := angle;
        end;


        within_bounds := true;
        for v := 0 to 3 do
        begin
          if ( surfaces[k]._2vertices[v].distance_vertex_camera < surfaces[k]._2vertices[v].distance_camera_intersection)
            or ( surfaces[k]._2vertices[v].distance_vertex_intersection > MAX_VIEWING_DISTANCE)
            or ( abs(surfaces[k]._2vertices[v].angle) > pi/2)
          then
          begin
            within_bounds := false;
            break;
          end;
        end;
        if within_bounds then
        begin
            screen.Canvas.Brush.color := surfaces[k].color;
            screen.Canvas.pen.color := surfaces[k].color;
          screen.Canvas.Polygon([
            point(screen.width div 2 + round((screen.width/2) * surfaces[k]._2vertices[0].x),
              screen.height div 2 - round( (screen.height/2) * surfaces[k]._2vertices[0].y)),
            point(screen.width div 2 + round((screen.width/2) * surfaces[k]._2vertices[1].x),
              screen.height div 2 - round( (screen.height/2) * surfaces[k]._2vertices[1].y)),
            point(screen.width div 2 + round((screen.width/2) * surfaces[k]._2vertices[2].x),
              screen.height div 2 - round( (screen.height/2) * surfaces[k]._2vertices[2].y)),
            point(screen.width div 2 + round((screen.width/2) * surfaces[k]._2vertices[3].x),
              screen.height div 2 - round( (screen.height/2) * surfaces[k]._2vertices[3].y))
          ]);


        end;
  end;

  // draw screen cross
{  screen.canvas.Pen.color := rgb(100, 100, 100);
  screen.canvas.MoveTo(screen.width div 2 - 10, screen.Height div 2);
  screen.canvas.lineTo(screen.width div 2 + 10, screen.Height div 2);
  screen.canvas.MoveTo(screen.width div 2, screen.Height div 2 - 10);
  screen.canvas.lineTo(screen.width div 2, screen.Height div 2 + 10);
   }


  // parameter for line
  rx := uux * SCREEN_WIDTH * (coordx - screen.width div 2) / screen.width -
    nnx * SCREEN_HEIGHT * (coordy - screen.height div 2) / screen.height;
  ry := uuy * SCREEN_WIDTH * (coordx - screen.width div 2) / screen.width -
    nny * SCREEN_HEIGHT * (coordy - screen.height div 2) / screen.height;
  rz := uuz * SCREEN_WIDTH * (coordx - screen.width div 2) / screen.width -
    nnz * SCREEN_HEIGHT * (coordy - screen.height div 2) / screen.height;

  rx := rx + cx + camera.vx;
  ry := ry + cy + camera.vy;
  rz := rz + cz + camera.vz;

  //vector from camera to plane intersection    s
  // c = camera
  // a = intersection - camera 
  ax := rx - cx;
  ay := ry - cy;
  az := rz - cz;

  t := cz / (cz - rz);

  // this is the intersection point on the ground plane
  inter_x := cx + ax * t;
  inter_y := cy + ay * t;
  inter_z := cz + az * t;


  

  screen.canvas.brush.color := clwhite;
end;

procedure process_physics();
var                                
  i, j, k : integer;
  x, y, z : real;
begin
{  camera.z := camera.z + camera.yveloc;
  if camera.z > 80 then
    camera.yveloc := camera.yveloc - 0.3;
  if camera.z < 80 then camera.z := 80;}
end;

procedure animate();
var
  i, j, k : integer;
begin

 

end;





procedure Tfmain.FormActivate(Sender: TObject);
var
  i, j, k : integer;
  x, y, z : real;
begin
 
  oldheight := screen.Height;
  oldwidth := screen.Width;
	//SetScreenResolution(640, 480, 8);

  while not Application.Terminated do
  begin
    clock := clock + 1;
    read_keyboard();

    animate();
    process_physics();
    draw_maps();
    draw_perspective();
    update_info();

    fmain.fscreen.canvas.Draw(0, 0, screen);
    fmap.mapxy.canvas.Draw(0, 0, mapscreen);
    application.ProcessMessages;
  end;

end;

procedure Tfmain.Exit1Click(Sender: TObject);
begin
  application.Terminate;
end;

procedure Tfmain.FormDestroy(Sender: TObject);
begin
   SetScreenResolution(oldwidth, oldheight, 32);
end;



procedure Tfmain.fscreenClick(Sender: TObject);
begin

  //distance :=
end;

procedure Tfmain.fscreenMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  coordx := x;
  coordy := y;
  statusbar1.Panels[0].Text := 'X: ' + inttostr(X) + ', Y: ' + inttostr(y);



  if clicked then
  begin
    case tool of
      ttoolline:
      begin
        surfaces[surface_index]._3vertices[vertex_index].x := coordx;
        surfaces[surface_index]._3vertices[vertex_index].y := coordy;
        surfaces[surface_index]._3vertices[vertex_index].z := 0;
      end;

      ttoolsurface:
      begin
        if getkeystate(vk_shift) < 0 then
        begin
          height2 := ftools.spinedit1.Value;
          surfaces[surface_index]._3vertices[1].x := inter_x;
          surfaces[surface_index]._3vertices[1].y := inter_y;
          surfaces[surface_index]._3vertices[1].z := surfaces[surface_index]._3vertices[0].z;
          surfaces[surface_index]._3vertices[2].x := inter_x;
          surfaces[surface_index]._3vertices[2].y := inter_y;
          surfaces[surface_index]._3vertices[2].z := height2 + ftools.spinedit2.value;
        end
        else
        begin
          surfaces[surface_index]._3vertices[1].x := inter_x;
          surfaces[surface_index]._3vertices[1].y := surfaces[surface_index]._3vertices[0].y;
          surfaces[surface_index]._3vertices[1].z := ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[2].x := inter_x;
          surfaces[surface_index]._3vertices[2].y := inter_y;
          surfaces[surface_index]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[3].x := surfaces[surface_index]._3vertices[0].x;
          surfaces[surface_index]._3vertices[3].y := inter_y;
          surfaces[surface_index]._3vertices[3].z := 0;
        end;
      end;
    end;
  end;

  


{  if fmain.checkbox1.checked then
  begin
    if mouse_counter = 0 then
  begin
    oldx := mouse.CursorPos.X;
    oldy := mouse.CursorPos.y;
  end;

  mouse_counter := mouse_counter + 1;
  if mouse_counter = 2 then
  begin
    if mouse.CursorPos.x <> oldx then
      camera.theta := camera.theta + 4*pi*((mouse.cursorpos.x - oldx) / screen.width);
      
    if mouse.CursorPos.y <> oldy then
      camera.phi := camera.phi + 2*pi*((mouse.cursorpos.y - oldy) / screen.height);

    mouse_counter := 0;
  end;
  end;  }



end;

procedure Tfmain.CheckBox1Click(Sender: TObject);
begin
  if checkbox1.Checked then
    setcursorpos(fmain.left + screen.width div 2, fmain.top + screen.Height div 2);

  labelededit1.SetFocus;
end;

procedure Tfmain.fscreenMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if clicked then
  begin

    case tool of
      ttoolline:
      begin
          surfaces[surface_index]._3vertices[vertex_index].x := coordx;
          surfaces[surface_index]._3vertices[vertex_index].y := coordy;
          surfaces[surface_index]._3vertices[vertex_index].z := 0;
          surface_index := surface_index + 1;
      end;
      ttoolsurface:
      begin
        surface_index := surface_index + 1;
      end;
    end;
    clicked := false;

    vertex_index := 0;
  end
  else
  begin
    
    height1 := coordy;
    case tool of
      ttoolline:
      begin
          surfaces[surface_index]._3vertices[0].x := coordx;
          surfaces[surface_index]._3vertices[0].y := coordy;
          surfaces[surface_index]._3vertices[0].z := ftools.spinedit2.value;
          clicked := true;
      end;
      ttoolsurface:
      begin
        clicked := true;
        if getkeystate(vk_shift)  < 0 then
        begin
          surfaces[surface_index]._3vertices[0].x := inter_x;
          surfaces[surface_index]._3vertices[0].y := inter_y;
          surfaces[surface_index]._3vertices[0].z := ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[3].x := inter_x;
          surfaces[surface_index]._3vertices[3].y := inter_y;
          surfaces[surface_index]._3vertices[3].z := ftools.spinedit1.value + ftools.spinedit2.value;
        end
        else
        begin

          surfaces[surface_index]._3vertices[0].x := inter_x;
          surfaces[surface_index]._3vertices[0].y := inter_y;
          surfaces[surface_index]._3vertices[0].z := 0;
          
        end;

      end;
      ttool_block:
      begin
          surfaces[surface_index]._3vertices[0].x := inter_x;
          surfaces[surface_index]._3vertices[0].y := inter_y;
          surfaces[surface_index]._3vertices[0].z := 0;
          surfaces[surface_index]._3vertices[1].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[1].y := inter_y;
          surfaces[surface_index]._3vertices[1].z := 0;
          surfaces[surface_index]._3vertices[2].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[2].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[2].z := 0;
          surfaces[surface_index]._3vertices[3].x := inter_x;
          surfaces[surface_index]._3vertices[3].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index]._3vertices[3].z := 0;

          surfaces[surface_index + 1]._3vertices[0].x := inter_x;
          surfaces[surface_index + 1]._3vertices[0].y := inter_y;
          surfaces[surface_index + 1]._3vertices[0].z := ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[1].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[1].y := inter_y;
          surfaces[surface_index + 1]._3vertices[1].z := ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[2].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[2].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[3].x := inter_x;
          surfaces[surface_index + 1]._3vertices[3].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 1]._3vertices[3].z := ftools.spinedit2.value;

          surfaces[surface_index + 2]._3vertices[0].x := inter_x;
          surfaces[surface_index + 2]._3vertices[0].y := inter_y;
          surfaces[surface_index + 2]._3vertices[0].z := 0;
          surfaces[surface_index + 2]._3vertices[1].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 2]._3vertices[1].y := inter_y;
          surfaces[surface_index + 2]._3vertices[1].z := 0;
          surfaces[surface_index + 2]._3vertices[2].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 2]._3vertices[2].y := inter_y;
          surfaces[surface_index + 2]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index + 2]._3vertices[3].x := inter_x;
          surfaces[surface_index + 2]._3vertices[3].y := inter_y;
          surfaces[surface_index + 2]._3vertices[3].z := ftools.spinedit2.value;

          surfaces[surface_index + 3]._3vertices[0].x := inter_x;
          surfaces[surface_index + 3]._3vertices[0].y := inter_y;
          surfaces[surface_index + 3]._3vertices[0].z := 0;
          surfaces[surface_index + 3]._3vertices[1].x := inter_x;
          surfaces[surface_index + 3]._3vertices[1].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 3]._3vertices[1].z := 0;
          surfaces[surface_index + 3]._3vertices[2].x := inter_x;
          surfaces[surface_index + 3]._3vertices[2].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 3]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index + 3]._3vertices[3].x := inter_x;
          surfaces[surface_index + 3]._3vertices[3].y := inter_y;
          surfaces[surface_index + 3]._3vertices[3].z := ftools.spinedit2.value;

          surfaces[surface_index + 4]._3vertices[0].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[0].y := inter_y;
          surfaces[surface_index + 4]._3vertices[0].z := 0;
          surfaces[surface_index + 4]._3vertices[1].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[1].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[1].z := 0;
          surfaces[surface_index + 4]._3vertices[2].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[2].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[3].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 4]._3vertices[3].y := inter_y;
          surfaces[surface_index + 4]._3vertices[3].z := ftools.spinedit2.value;

          surfaces[surface_index + 5]._3vertices[0].x := inter_x;
          surfaces[surface_index + 5]._3vertices[0].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[0].z := 0;
          surfaces[surface_index + 5]._3vertices[1].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[1].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[1].z := 0;
          surfaces[surface_index + 5]._3vertices[2].x := inter_x + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[2].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[2].z := ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[3].x := inter_x;
          surfaces[surface_index + 5]._3vertices[3].y := inter_y + ftools.spinedit2.value;
          surfaces[surface_index + 5]._3vertices[3].z := ftools.spinedit2.value;

          surfaces[surface_index].color := rgb(0, 0, 255);
          surfaces[surface_index +1].color := rgb(0, 0, 255);
          surfaces[surface_index+2].color := rgb(0, 0, 200);
          surfaces[surface_index+3].color := rgb(0, 0, 100);
          surfaces[surface_index+4].color := rgb(0, 0, 150);
          surfaces[surface_index+5].color := rgb(0, 0, 255);
          
          surface_index := surface_index + 6;
      end;
    end;
    

  end;
   
end;

end.
