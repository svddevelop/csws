unit u_objhelper;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  T_Method = procedure of Object;

function getSelfOfObjectByMethod(aFree: T_Method): TObject;


implementation

function getSelfOfObjectByMethod(aFree: T_Method): TObject;
var
  mthd: TMethod absolute aFree;
begin
  Result := TObject(mthd.Code);
end;


end.

