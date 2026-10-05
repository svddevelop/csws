unit u_strparams;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, RegExpr, SysUtils;

type

  { TStrParamList }

  TStrParamList = class (TStringList)
    public
      const
       c_prefix = '$(';
       c_suffix = ')';

       c_expr = '\$\(([^)]+)\)';
  public
    Regex: TRegExpr;
    function FindRegexMatches(const aInputString, aExpr: string): TStringArray;
  public
    constructor Create;
    destructor Destroy; override;
    procedure init;
    function change(var aStr: String): Integer;
  end;

implementation

uses u_conf{$IFDEF Windows}, Windows{$ENDIF}


  , u_versionsinfo
  ;

function GetRaspberryPiSerialNumber: string;
{$ifdef unix}
var
  CpuInfo: TStringList;
  Line: string;
  {$endif}
begin
  Result := '';
  {$ifdef unix}
  CpuInfo := TStringList.Create;
  try
    // Read the content of the /proc/cpuinfo file
    CpuInfo.LoadFromFile('/proc/cpuinfo');
    // Search for the line with the serial number
    for Line in CpuInfo do
    begin
      if Pos('Serial', Line) = 1 then // Search for the line which begins with "Serial"
      begin
        Result := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line))); // Extract the value
        Break;
      end;
    end;
  finally
    CpuInfo.Free;
  end;
  {$endif}
end;

procedure ReadEnvironmentVariables(EnvList: TStringList);
{$IFDEF Windows}
var
  EnvStrings: PChar;
  P: PChar;
  EnvEntry: string;
{$else}
var
  i : Integer;
  s,v: ansistring;
{$ENDIF}
begin
  if not Assigned(EnvList) then
    raise Exception.Create('EnvList is not assigned');

  EnvList.Clear;

  {$IFDEF Windows}
  EnvStrings := GetEnvironmentStrings;
  try
    P := EnvStrings;
    while P^ <> #0 do
    begin
      EnvEntry := StrPas(P);
      EnvList.Add(EnvEntry);
      Inc(P, Length(EnvEntry) + 1);
    end;
  finally
    FreeEnvironmentStrings(EnvStrings);
  end;
  {$ELSE}
  // Linux and other Unix-like systems
  for i := 0 to GetEnvironmentVariableCount-1 do
  begin
    s := GetEnvironmentString(i);
    v := GetEnvironmentVariable(s);
    Writeln('ReadEnvironmentVariables('+s+'='+v+')');
    EnvList.add( s + EnvList.Delimiter + v);
  end;
  {$ENDIF}
end;
{ TStrParamList }

function TStrParamList.FindRegexMatches(const aInputString, aExpr: string): TStringArray;
var
  MatchCount : Integer;
begin
  Result := nil;
  MatchCount := 0;

  try
    Regex.Expression := aExpr;

    if Regex.Exec(aInputString) then
    begin
      repeat
        Inc(MatchCount);
        SetLength(Result, MatchCount);
        Result[MatchCount - 1] := Regex.Match[1];
      until not Regex.ExecNext;
    end;
  finally
  end;
end;

constructor TStrParamList.Create;
begin
  Regex:= TRegExpr.Create;
end;

destructor TStrParamList.Destroy;
begin
  Regex.Free;
  inherited Destroy;
end;

procedure TStrParamList.init;
begin
   ReadEnvironmentVariables(Self);
   Add('SerialNumber='+ GetRaspberryPiSerialNumber());
   u_versionsinfo.ReadVersionInfoParams(System.HINSTANCE, Self);

   //t := Self.Text;
   //writeln('TStrParamList.init:' + t);
end;

function TStrParamList.change(var aStr: String): Integer;
var
  i,j,k : Integer;
  p,v : string;
  sa : TStringArray;
begin
  Result := 0;

  for i := 0 to Count-1 do
  begin
    p := c_prefix + Names[i] + c_suffix;
    v := ValueFromIndex[i];
    aStr := StringReplace(aStr, p, v, [rfReplaceAll, rfIgnoreCase], j);
    inc(result, j);
  end;

  if assigned(u_conf.Config) then
  begin
    i := 0;
    j := Config.getParamsCount();
    while (i < j) do
    begin
      p := Config.params[i];
      if length(p) > 0 then
      begin
        v := Config.asString[p];
        p := c_prefix + p + c_suffix;
        aStr := StringReplace(aStr, p, v, [rfReplaceAll, rfIgnoreCase], k);
        inc(result, k);
      end;
      inc(i);
    end;

  end;

  //sa := FindRegexMatches(aStr, c_expr);

end;

end.

