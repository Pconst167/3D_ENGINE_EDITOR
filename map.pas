unit map;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, unit1;

type
  Tfmap = class(TForm)
    GroupBox3: TGroupBox;
    mapxy: TPaintBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmap: Tfmap;

implementation

{$R *.dfm}

end.
