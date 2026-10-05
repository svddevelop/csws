unit u_conf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TConfig }

  TConfig = class
  public
    const
      C_IDX_NORMAL = 0;
      C_IDX_PROTECTED = 1;
  private
    FToken: String;
    FTokenDate: TDateTime;
    FisChanged: Boolean;
    FLastReadedFile: String;
    function getIsTokenExpired: Boolean;
    function getParams(const aIdx: Integer): String;
    function getSSLLibDir: String;
    function getToken: String;
    function getTokenDate: TDateTime;
    procedure setValue( ParamName: string;  aIdx: Integer; AValue: string);
  protected
    FSections, FParams, FValues: TStringArray;

    function getIdxFromStringArray(var aSA:TStringArray; aText: string): Integer;
    function getValue( aParamName: string; aIdx: Integer): string;
    function getValueBase64( aParamName: string): string;
    function getValueInt( aParamName: string): Integer;
    function getValueBool( aParamName: string): Boolean;
    function addInStringArray( var aSA: TStringArray; aText: String): Integer;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   readConfigFile( aConfFileName: String );
    procedure   writeConfigFile( aConfFileName: String);
    procedure   saveConfig;
    procedure   makeConfigFile( aConfFileName: String );
    function    paramExist( aParamName: string ): Boolean;
    property    asString[ ParamName: string]: string index C_IDX_NORMAL read getValue write setValue;
    property    asBase64[ ParamName: string]: string read getValueBase64;
    property    asInt[ ParamName: string]: Integer read getValueInt;
    property    asBool[ ParamName: string]: Boolean read getValueBool;
    property    asProtectedAsString[ ParamName: string]: string index C_IDX_PROTECTED read getValue write setValue;
    property    SSLLibDir: String read getSSLLibDir;

    property isCfgChanged: Boolean read FisChanged;

    property Token: String read getToken write FToken;
    property TokenDate: TDateTime read getTokenDate write FTokenDate;
    property isTokenExpired: Boolean read getIsTokenExpired;
    property params[const aIdx: Integer]: String read getParams;
    function getParamsCount(): Integer;
    procedure deleteParam(const aIdx: Integer);
  public
    class var ConfigInstance: TConfig;
    class function  encode_str( aStr: RawByteString): RawByteString;
    class function  decode_str( aStr: RawByteString): RawByteString;

  protected
    FMQConnCount : Word;
  public
    type TMQConn = packed record
              Name,Server,User,PWD,VHost,Exchange
                ,Queue,Method,URL,FileName, RKey: RawByteString;
              Port: Word;
          end;
    class var ini_filename: String;
    property  MQConnCount: Word read FMQConnCount;
    function  readMQConn(const aConfFileName: String;const aIdx: Word;var aMQConn : TMQConn ): Boolean;
    procedure initMQConn( var aMQConn : TMQConn);
    function  isMQConnCorrect(  aMQConn : TMQConn): boolean;

  public
    procedure addmenu(const aMenuCaption, aMenuCmd: String);

  public
    type
      T_CFG_SEC = packed record
        SEC_NAME: String;
        PARAMS: array of String;
        DEFVAL: array of String;
        TXT: array of String;
      end;
      T_CFG_FULL = packed array of T_CFG_SEC;

    const
         C_SECOND_IN_DAY                 = 1/( 24 * 60 * 60);

         C_SEC_MENU                      = 'MENU';
         C_SEC_APP                       = 'APPLICATION';
         C_PAR_Port                      = 'PORT';
         C_PAR_TH_DIR                    = 'RootPath';
         C_PAR_IDXFN                     = 'RootFileName';
         C_PAR_WorkDir                   = 'TempPath';
         C_PAR_MenuCaption               = 'MenuCaption';
         C_PAR_MenuCmd                   = 'MenuCommand';
         {$ifdef UNIX}
         C_DPV_TH_Dir                   = '/var/techtool/thtml/';
         {$else}
         C_DPV_TH_Dir                   = './.var_thtml/';
         {$endif}

         {$ifdef UNIX}
         C_DPV_WorkDir                   = '/tmp/';
         {$else}
         C_DPV_WorkDir                   = './.workdir/';
         {$endif}
         C_DPV_IDXFN                     = 'index.thtml';

         C_TXT_Port                      = 'Web access port';
         C_TXT_TH_DIR                    = 'Path to templates HTML files';
         C_TXT_IDXFN                     = 'name of default HTML-template'#13#10'RootFileName=index.thtml';

         C_TXT_WorkDir                   = 'Temporary catalog';



         C_FULL_CFG: packed array of T_CFG_SEC = (
           (SEC_NAME: C_SEC_APP
             ; PARAMS:(
                  C_PAR_Port, C_PAR_TH_DIR, C_PAR_IDXFN
                  , C_PAR_WorkDir
             )

             ; DEFVAL:(
                  '8080', C_DPV_TH_Dir, C_DPV_IDXFN
                  , C_DPV_WorkDir
             )
             ; TXT:(
                  C_TXT_Port, C_TXT_TH_DIR, C_TXT_IDXFN
                  , C_TXT_WorkDir
             )
           )   (*
           ,
           (SEC_NAME: C_SEC_DB
             ; PARAMS:(
                  C_PAR_DBTYPE, C_PAR_DBHost, C_PAR_Database, C_PAR_DBUser, C_PAR_DBPwd
                  , C_PAR_CHARSET, C_PAR_DBLIB
             )
             ; DEFVAL:(
                  C_DPV_DBTYPE, C_DPV_DBHost, C_DPV_Database, C_DPV_DBUser, C_DPV_DBPwd
                  , C_DPV_CHARSET, C_DPV_DBLIB
             )
             ; TXT:(
                  C_TXT_DBTYPE, C_TXT_DBHost, C_TXT_Database, C_TXT_DBUser, C_TXT_DBPwd
                  , C_TXT_CHARSET, C_TXT_DBLIB
             )
           )
           ,
           (SEC_NAME: C_SEC_TPL
             ; PARAMS:(
                  C_PAR_TPLMQHURLPUT
             )
             ; DEFVAL:(
                  C_DPV_TPLMQHURLPUT
             )
             ; TXT:(
                  C_TXT_TPLMQHURLPUT
             )
           )
           ,
           (SEC_NAME: C_SEC_MQ
             ; PARAMS:(
                  C_PAR_MQCONN
             )
             ; DEFVAL:(
                  C_DPV_MQCONN
             )
             ; TXT:(
                  C_TXT_MQCONN
             )
           )     *)
         );
    var FULL_CFG: packed array of T_CFG_SEC;
  end;

var
    Config : TConfig;

implementation

uses
    inifiles
  , Base64
  //, u_ownlogger
  , StrUtils
  ;

{ TConfig }

class function TConfig.encode_str(aStr: RawByteString): RawByteString;
var
  rs,cs: rawbytestring;
  i,j,k : Integer;
begin
  rs := aStr;
  cs := TConfig.ClassName;
  k := length(cs);
  for i := 1 to length(rs) do
  begin
    j :=i mod k;
    if j = 0 then inc(j);
    rs[i] := AnsiChar(byte(rs[i]) xor byte(cs[j]));
  end;
  Result := EncodeStringBase64( rs );
end;

class function TConfig.decode_str(aStr: RawByteString): RawByteString;
var
  rs,cs: rawbytestring;
  i,j,k : Integer;
begin
  rs := DecodeStringBase64( aStr );
  cs := TConfig.ClassName;
  k := length(cs);
  for i := 1 to length(rs) do
  begin
    j :=i mod k;
    if j = 0 then inc(j);
    rs[i] := AnsiChar(byte(rs[i]) xor byte(cs[j]));
  end;
  Exit( rs );
end;

function TConfig.readMQConn(const aConfFileName: String;const aIdx: Word;var aMQConn: TMQConn): Boolean;
var
   SL: TStringList;
   i, k : Integer;
   port : longint;
   s : string;

   function getSubparam( aStr, aParam: String ): String;
   var
      p, g,sk: integer;
   begin
     Result := '';
     p := pos( aParam, aStr );
     if p <= 0 then exit;

     g := PosEx('=', aStr, p +1);
     if g <= 0 then Exit;

     sk := PosEx( ';', aStr, g +1);
     if sk <= 0 then sk := length(aStr) +1;

     Result := copy(aStr, g +1, sk - g -1);
   end;

begin
  WriteLn('Config.ReadMQConn:' + aConfFileName );
  initMQConn( aMQConn );
  FLastReadedFile := aConfFileName;
  if FileExists( aConfFileName ) then
    with TIniFile.Create( aConfFileName ) do
    try
      SL := TStringList.Create;
//      ReadSectionRaw(C_SEC_MQ, SL);

      k := 0;
      for i := 0 to SL.Count -1 do
      begin
        s := Trim(SL[i]);
//        if pos( C_PAR_MQCONN , s) = 1 then
          begin
            inc(k);
            if k = aIdx then
            begin
               aMQConn.Name:= getSubparam( s, 'Name');
               aMQConn.Method:= getSubparam( s, 'Method');
               aMQConn.Exchange:= getSubparam( s, 'Exchange');
               aMQConn.PWD:= getSubparam( s, 'PWD');
               aMQConn.Queue:= getSubparam( s, 'Queue');
               aMQConn.Server:= getSubparam( s, 'Server');
               aMQConn.VHost:= getSubparam( s, 'VHost');
               aMQConn.URL:= getSubparam( s, 'URL');
               aMQConn.User:= getSubparam( s, 'User');
               aMQConn.RKey:= getSubparam( s, 'RKey');
               aMQConn.FileName := getSubparam( s, 'PayloadFile' );
               if TryStrToInt( getSubparam( s, 'Port'), port ) then aMQConn.Port := port;
               Result := isMQConnCorrect( aMQConn );
               Exit;
            end;
          end;
      end;

    finally
      SL.Free;
      Free;
    end;

end;

procedure TConfig.initMQConn(var aMQConn: TMQConn);
begin
  aMQConn.Exchange := '';
  aMQConn.Method   := '';
  aMQConn.Name     := '';
  aMQConn.PWD      := '';
  aMQConn.Queue    := '';
  aMQConn.Server   := '';
  aMQConn.URL      := '';
  aMQConn.User     := '';
  aMQConn.VHost    := '';
  aMQConn.RKey     := '';
  aMQConn.Port     := 0;
end;

function TConfig.isMQConnCorrect(aMQConn: TMQConn): boolean;
begin
  Result := ( aMQConn.Port > 0)
         and( length(aMQConn.Server) > 0)
         ;
end;

procedure TConfig.addmenu(const aMenuCaption, aMenuCmd: String);
var
   ini: TIniFile;
   sl: TStringList;
   i : Integer;
   s : String;
begin
   if FileExists(ini_filename)then
   begin
     sl := TStringList.Create;
     ini := TIniFile.Create(ini_filename);
     try
       ini.ReadSections(sl);

       for i := SL.Count-1 downto 0 do
       begin
         s := SL[i];
         if not s.StartsWith(C_SEC_MENU) then
           SL.Delete(i);
       end;

       i := SL.Count +1;
       s := C_SEC_MENU + IntToStr(i);
       ini.WriteString(s, C_PAR_MenuCaption, aMenuCaption);
       ini.WriteString(s, C_PAR_MenuCmd, aMenuCmd);
     finally
       ini.free;
       sl.free;
     end;
   end;
end;


function TConfig.getValue( aParamName: string;  aIdx: Integer): string;
var
  i : Integer;
begin
  Result := '';
  aParamName:= UpperCase(aParamName);
  i := getIdxFromStringArray(FParams, aParamName);
  if i >= 0 then
  begin
    if aIdx = C_IDX_PROTECTED then
       Exit( decode_str( FValues[i] ))
    else
       Exit(FValues[i]);
  end;
end;

function TConfig.addInStringArray(var aSA: TStringArray; aText: String
  ): Integer;
begin
  Result := length( aSA );
  SetLength( aSA, Result +1 );
  aSA[Result] := aText;
end;

function TConfig.getValueInt( aParamName: string): Integer;
begin
  Result := 0;
  TryStrToInt(asString[aParamName], Result);
end;

function TConfig.getValueBool( aParamName: string): Boolean;
begin
  Result := False;
  TryStrToBool( asString[aParamName], Result);
end;

function TConfig.getValueBase64( aParamName: string): string;
begin
  Result :=DecodeStringBase64( asString[aParamName] );
end;

function TConfig.getIsTokenExpired: Boolean;
begin
  Result := Now  > (FTokenDate - ( 10 * C_SECOND_IN_DAY ) );
  if Result then
    SetLength(FToken, 0) ;
end;

function TConfig.getParams(const aIdx: Integer): String;
begin
  Result := '';
  if (aIdx >= 0) and (aIdx < getParamsCount()) then
    Result := FParams[aIdx];
end;

function TConfig.getSSLLibDir: String;
begin
  Result := ChangeFileExt( ParamStr(0), '_lib/');
end;

function TConfig.getToken: String;
begin
  Result := IfThen( isTokenExpired, '', FToken);
end;

function TConfig.getTokenDate: TDateTime;
begin
  Result := 0;
  if not isTokenExpired then
    Result := FTokenDate;
end;

procedure TConfig.setValue( ParamName: string; aIdx: Integer; AValue: string);
var
  i : Integer;
  s : String;
begin
  s := ifthen( aIdx = C_IDX_PROTECTED, encode_str(AValue), AValue);
 i := getIdxFromStringArray(FParams, ParamName);
 if i >= 0 then
 begin
   if FValues[i] <> AValue then
   begin
     FValues[i] := s;
     FisChanged := True;
   end;
 end
 else
 begin
   FisChanged := True;
   addInStringArray(FParams, ParamName);
   addInStringArray(FValues, s);
 end;
end;

function TConfig.getIdxFromStringArray(var aSA: TStringArray; aText: string ): Integer;
var
   i,l : Integer;
begin
 Result := -1;
 l := length(aSA);
 for i := 0 to l -1 do
   if aSA[i] = aText then
     Exit(i);
end;

constructor TConfig.Create;
var
   s: String;
begin
  WriteLn('Config.Create begin');
  ConfigInstance := Self;
  SetLength(FSections, 0);
  SetLength(FParams, 0);
  SetLength(FValues, 0);
  FisChanged:= False;
  s := ParamStr(0);
  {$ifdef UNIX}
  s := ChangeFileExt(s, '.conf');
  {$endif}
  {$ifdef WINDOWS}
  s := ChangeFileExt(s, '.ini');
  {$endif}
  // s is always the default file name, even when the file does not exist yet;
  // otherwise operations like makeConfigFile would get an empty path
  ini_filename := s;
  if FileExists( s ) then
    ini_filename:= s
    {$ifdef UNIX}
    else
    begin
      s := '/etc/' + ExtractFileName(s);
      if FileExists( s ) then
          ini_filename:= s
    end
    {$endif}
  ;
 WriteLn('Config.Create end ' + ini_filename);
end;

destructor TConfig.Destroy;
begin
 WriteLn('Config.Destroy begin');
  ConfigInstance := nil;
  SetLength(FSections, 0);
  SetLength(FParams, 0);
  SetLength(FValues, 0);
  inherited Destroy;
 WriteLn('Config.Destroy end');
end;

procedure TConfig.readConfigFile(aConfFileName: String);
var
   SL: TStringList;
   i,j,k, l : Integer;
   s : string;
begin
  WriteLn('Config.ReadConfigFile:' + aConfFileName );
  FLastReadedFile := aConfFileName;
  if FileExists( aConfFileName ) then
    with TIniFile.Create( aConfFileName ) do
    try
      SetLength(FSections, 0);
      SetLength(FParams, 0);
      SetLength(FValues, 0);

      SL := TStringList.Create;
      ReadSections(SL);

      for i := 0 to SL.Count -1 do
        addInStringArray( FSections, UpperCase( SL[i] ));


      l := length(FSections);
      for i := 0 to l -1 do
      begin
          SL.Clear;
          ReadSectionRaw(FSections[i], SL);
          for j := 0 to SL.Count -1 do
            begin
              if length(SL.ValueFromIndex[j]) > 0 then
                begin
                   s := FSections[i] + UpperCase( Trim(SL.Names[j]) );

                   k := getIdxFromStringArray(FParams, s);
                   if k >= 0 then
                     asString[s] := SL.ValueFromIndex[j]
                   else
                   begin
                     addInStringArray(FParams, Trim(s));
                     addInStringArray(FValues, Trim(SL.ValueFromIndex[j]) );
                   end;

                end;
            end;
      end;
      SetLength(FSections, 0);
    finally
      FisChanged := False;
      SL.Free;
      Free;
      WriteLn('Config.readConfigFile end');
    end;
end; //procedure TConfig.readConfigFile

procedure TConfig.writeConfigFile(aConfFileName: String);
var
   i , j : Integer;
   s, sp : String;
begin
  Writeln('writeConfigFile:'+aConfFileName);
  FisChanged := False;
  with TIniFile.Create(aConfFileName) do
  try
    for i := low(C_FULL_CFG) to high(C_FULL_CFG) do
    begin
      for j := low( C_FULL_CFG[i].PARAMS ) to high( C_FULL_CFG[i].PARAMS ) do
      begin
        s := C_FULL_CFG[i].DEFVAL[j];
        sp := C_FULL_CFG[i].SEC_NAME + C_FULL_CFG[i].PARAMS[j];
        if paramExist(sp) then
          s := asString[ sp ];
        WriteString(C_FULL_CFG[i].SEC_NAME, C_FULL_CFG[i].PARAMS[j], s);
      end;
    end;
  finally
    Free;
  end;
end;

procedure TConfig.saveConfig;
begin
 if FileExists(FLastReadedFile) then

    writeConfigFile( FLastReadedFile );
end;

procedure TConfig.makeConfigFile(aConfFileName: String);
var
   i, j : Integer;
   s : AnsiString;
   fs : TFileStream;
begin

  FS := TFileStream.Create( aConfFileName, fmCreate );
  try
    for i := low(C_FULL_CFG) to high(C_FULL_CFG) do
    begin
      s := '[' + C_FULL_CFG[i].SEC_NAME + ']'#13#10;
      FS.WriteBuffer( pointer(s)^, length(s));
      for j := low(C_FULL_CFG[i].PARAMS) to high(C_FULL_CFG[i].PARAMS) do
      begin
        s := ';; '+ C_FULL_CFG[i].TXT[j] + #13#10 +  C_FULL_CFG[i].PARAMS[j]
             + #9'='#9 + C_FULL_CFG[i].DEFVAL[j] + #13#10;
        FS.WriteBuffer( pointer(s)^, length(s));
      end;
    end;
  finally
    FS.Free;
  end;
end;

function TConfig.paramExist(aParamName: string): Boolean;
var
   i : Integer;
begin
  i := getIdxFromStringArray(FParams, aParamName);
  Result := i >= 0;
end;

function TConfig.getParamsCount(): Integer;
begin
  Result := Length(FParams);
end;

procedure TConfig.deleteParam(const aIdx: Integer);
var
   i : Integer;
begin
   if aIdx < 0 then Exit;

   for i := aIdx +1 to Length(FParams)-1 do
   begin
     FParams[i-1] := FParams[i];
     FValues[i-1] := FValues[i];
   end;

   i := Length(FParams) -1;

   SetLength(FParams, i);
   SetLength(FValues, i);
end;

end.


