unit tools;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, unit1, Spin, ComCtrls;

type
  Tftools = class(TForm)
    Panel1: TPanel;
    GroupBox2: TGroupBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    SpinEdit2: TSpinEdit;
    SpinEdit1: TSpinEdit;
    Label1: TLabel;
    TrackBar1: TTrackBar;
    Label2: TLabel;
    TrackBar3: TTrackBar;
    Label3: TLabel;
    TrackBar2: TTrackBar;
    TrackBar4: TTrackBar;
    Label4: TLabel;
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ftools: Tftools;

implementation

{$R *.dfm}

procedure Tftools.Button3Click(Sender: TObject);
begin
  tool := ttool_block;
end;

procedure Tftools.Button2Click(Sender: TObject);
begin
  tool := ttoolsurface;
end;

procedure Tftools.Button1Click(Sender: TObject);
begin
  tool := ttoolline;
end;

end.
