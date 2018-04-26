program _3point;

uses
  Forms,
  Unit1 in 'Unit1.pas' {fmain},
  tools in 'tools.pas' {ftools},
  map in 'map.pas' {fmap};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfmain, fmain);
  Application.CreateForm(Tftools, ftools);
  Application.CreateForm(Tfmap, fmap);
  Application.Run;
end.
