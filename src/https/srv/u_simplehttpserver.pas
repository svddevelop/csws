unit u_SimpleHTTPServer;

interface

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fphttpserver, u_strparams;

type

  { TSimpleHTTPServer }

  TSimpleHTTPServer = class(TFPHTTPServer)
  public const
     C_stop                   = 'stop';
     c_shell                  = 'shell';
     c_run                    = 'shellrun';
     c_response               = 'shellresponse';
     c_break                  = 'shellbreak';

     c_addenvvar              = 'addenvvar';

     c_plaintext              = 'plain/text';
     c_texthtml               = 'text/html';

     c_thtml                  = '.thtml';

     c_mnu_cap                = 'CAPTION';
     c_mnu_cmd                = 'CMD';
     c_mnu_clear              = 'CLEAR';
     c_mnu_default            = 'DEFAULT';

     c_html_rec_Code_ok       = 200;
     c_html_rec_Code_notfound = 404;
  public
    procedure HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse); override;
    procedure handleMenulist(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
    procedure handleMenu(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
    procedure handleTHfile(aTHFN: String;var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
    procedure handleImageRequest(ARequest: TFPHTTPConnectionRequest; AResponse: TFPHTTPConnectionResponse; const aMime: String);
    procedure handleUpload(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
    function  getIndexOfParams(aPar: string): Integer;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  public
    strParams: TStrParamList;
    str_html_shell,
    thpath
         : string;

    procedure read_thtml_from_file(var aStr: String; aFileName: String);
  public
    ResourceInstance : TComponent;
    procedure init;
    function  get_request_uri(const aURI: string): string;
    function  is_request_uri_thtml(aURI: String; var aTHFN: String): Boolean;
    function  is_request_uri_external_file(aURI: String; var aFN: String): Boolean;
    function  GetResourceAsString(const ResName: string): TBytes;
  end;

function ReadTextFileToString(const FileName: string): string;

var
  Server: TSimpleHTTPServer;


implementation

{$R favicon.res}

uses u_CommandExecutor
  , math
  , u_conf
  , LCLType
  , u_safememorystream
  , fileutil
  , u_mime_types
  , graphics
  ;




 //test: http://localhost:8080/shell?cmd=dir%20/s/b%20Z:\tmp\

function ReadTextFileToString(const FileName: string): string;
var
  FileStream: TFileStream;
  //StringStream: TStringStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    //StringStream := TStringStream.Create('', TEncoding.UTF8);
    //try
    //  StringStream.CopyFrom(FileStream, FileStream.Size); // Копируем данные из FileStream в StringStream
    //  Result := StringStream.DataString; // Получаем содержимое как строку
    //finally
    //  StringStream.Free;
    //end;
    SetLength(Result, FileStream.Size);
    FileStream.ReadBuffer(pointer(Result)^, FileStream.Size);
  finally
    FileStream.Free;
  end;
end;

function TSimpleHTTPServer.GetResourceAsString(const ResName: string): TBytes;
var
  ResStream: TResourceStream;
  RI : TFPResourceHMODULE;
  HInstance: QWord absolute RI;
begin
  RI := System.HINSTANCE;
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    SetLength(Result, ResStream.Size);
    ResStream.ReadBuffer(Result[0], ResStream.Size);
  finally
    ResStream.Free;
  end;
end;

var

  last_uri: String;
procedure   print_Request(const ARequest: TFPHTTPConnectionRequest; const aIgnoreUri: TStringArray);
var
  s : String;
begin
  try
    for s in aIgnoreUri do
      if ARequest.URI = s then
        Exit;

    Writeln('HandleRequest:URI:' + ARequest.URI);
    Writeln('params:' + ARequest.QueryString);
  finally
    last_uri := ARequest.URI;
  end;
end;

procedure TSimpleHTTPServer.HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
var
  uri, cmd, cropcmd: String;
  i : Integer;
  IconData: TBytes;
  ignorPrint: TStringArray;
  sa: TStringArray;
  s,ext, mime : String;
begin
  ignorPrint := ['/'+c_run, '/'+c_response];

  uri := ARequest.URI;
  print_Request( ARequest, ignorPrint );
  i := pos('?', uri);
  if i > 0 then
    delete(uri, i, length(uri));

  if uri = get_request_uri(c_stop) then
  begin
    Self.Active:= False;
    Exit;
  end;

  //if uri = get_request_uri('upload') then
  if ARequest.Files.Count > 0 then
  begin
    handleUpload(ARequest, AResponse);
    Exit;
  end;


  if uri = get_request_uri(c_shell) then
  begin
    cmd := ARequest.QueryFields.Values['cmd'];
    cropcmd := cmd;
    sa := cmd.Split([' ']);
    if length(sa) > 0 then
       cropcmd := sa[0];
    strParams.values['shellcommand'] := ExtractFileName(cropcmd);
    strParams.values['fullshellcommand'] := cmd;
    if (cmd <> '') then
    begin
      if CommandExecutor.FIsRunning then
        CommandExecutor.StopCmd;
      CommandExecutor.ExecCmd(cmd);

      read_thtml_from_file(str_html_shell, c_shell);
      AResponse.Content :=      str_html_shell;
      setLength(str_html_shell, 0);

      AResponse.Code:= c_html_rec_Code_ok;
      AResponse.ContentType := c_texthtml;
      AResponse.SendResponse; // Отправляем ответ
      Exit;
    end;
    Exit;
  end;

  if uri = get_request_uri(c_response) then
  begin
    begin
      cmd := SafeMemoryStream.PopRawByteString(1000);
      AResponse.Code:= c_html_rec_Code_ok;
      AResponse.Content:= cmd;
    end
    ;

    AResponse.ContentType := c_plaintext;
    AResponse.SendResponse; // Отправляем ответ
    Exit;
  end;

  if uri = get_request_uri(c_run) then
  begin
    if CommandExecutor.IsRunning then
    begin
      AResponse.Code:= c_html_rec_Code_ok;
    end
    else
    begin
       AResponse.Code:= c_html_rec_Code_notfound;
    end;

    AResponse.ContentType := c_plaintext;
    AResponse.SendResponse; // Отправляем ответ
    Exit;
  end;

  if uri = get_request_uri(c_break) then
  begin
      CommandExecutor.StopCmd;

      AResponse.Content:= '*** breaked ***';

      AResponse.Code:= c_html_rec_Code_ok;
      AResponse.ContentType := c_plaintext;
      AResponse.SendResponse; // Отправляем ответ
      Exit;
  end;

  if uri = get_request_uri('menulist') then
  begin
    handleMenulist(ARequest, AResponse);
    Exit;
  end;

  if uri = '/' then
  begin
    cmd := Config.asString[Config.C_SEC_APP+Config.C_PAR_IDXFN];
    cmd := ChangeFileExt(cmd, '');
    read_thtml_from_file(str_html_shell, cmd);
    AResponse.Content :=      str_html_shell;
    setLength(str_html_shell, 0);

    AResponse.ContentType := c_texthtml; // Устанавливаем тип контента
    AResponse.SendResponse; // Отправляем ответ
    Exit;
  end
  else
  if uri = '/favicon.ico' then
  begin
    AResponse.ContentType := 'image/x-icon';
    try
      IconData := GetResourceAsString('FAVICON');
      AResponse.ContentLength := Length(IconData);
      AResponse.ContentStream := TMemoryStream.Create;
      try
        AResponse.ContentStream.WriteBuffer(IconData[0], Length(IconData));
        AResponse.ContentStream.Position := 0;
        AResponse.SendContent;
      finally
        AResponse.ContentStream.Free;
      end;
    except on E: Exception do
      begin
           writeln('E:' + E.Message);
      end;
    end;
    Exit;
  end
  else

  if uri = get_request_uri('menu') then
  begin
    handleMenu(ARequest, AResponse);
    Exit;
  end
  else

  if is_request_uri_external_file(uri, cmd) then
  begin
    // check for many types of files
    mime := '';
    ext := ExtractFileExt(cmd);
    ext := ext.LowerCase(ext);
    if ext = '.jpg' then mime := c_img_jpeg;
    if ext = '.jpeg' then mime := c_img_jpeg;
    if ext = '.png' then mime := c_img_png;


    handleImageRequest(ARequest, AResponse, mime);
    Exit;
  end
  else
  if is_request_uri_thtml(uri, cmd) then
  begin
    handleTHfile(cmd, ARequest, AResponse);
    Exit;
  end
  else

  begin
    // Возвращаем 404 для неизвестных путей
    AResponse.Code := c_html_rec_Code_notfound;
    AResponse.Content :=
      '<html>' +
      '<head><title>404 Not Found</title></head>' +
      '<body>' +
      '<h1>404 Not Found</h1>' +
      '<p>The requested URL was not found on this server.</p>' +
      '</body>' +
      '</html>';
    AResponse.ContentType := c_texthtml;
    AResponse.SendResponse;
  end;
end;

procedure TSimpleHTTPServer.handleMenulist(var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);

  function paramname_2_idx_cap_cmd(const aParamName: String): Integer;
  var
    i,j : Integer;
    s : String;
  begin
    j := length(Config.C_SEC_MENU)+1;
    setLength(s,0);
    for i := j to length(aParamName) do
    begin
      if aParamName[i] in ['0'..'9'] then
        s := s + aParamName[i];
    end;
    TryStrToInt(s, Result);
  end;

var
  i,j : Integer;
  p,v,s,mc : String;
  b1,b2 : Boolean;
begin
  {*****************************************************************************
   Заголовок меню отделяется от URL символами  :=:
   Элементы разделяются символами #10

   example: 'menu1::/shell?cmd=dir /s Z:\tmp'#13#10'menu2::/shell?cmd=echo.do it'
  ******************************************************************************}
  //AResponse.Content :=  'menu1::/shell?cmd=dir /s Z:\tmp'#13#10'menu2::/shell?cmd=echo.do it';
  setLength(str_html_shell, 0);
  mc := UpperCase(Config.C_PAR_MenuCaption);
  for i := 0 to Config.getParamsCount() -1 do
  begin
    p := Config.params[i];

    b1 := p.StartsWith(Config.C_SEC_MENU);
    b2 := (pos(mc, p) > 0);
    if b1 and b2 then
    begin
      j := paramname_2_idx_cap_cmd(p);
      s := Config.C_SEC_MENU+ IntToStr(j) + mc;
      p := Config.asString[s];
      s := Config.C_SEC_MENU+ IntToStr(j) + UpperCase(Config.C_PAR_MenuCmd);
      //v := '/' + c_shell + '?cmd=' + Config.asString[s];
      v := Config.asString[s];

      Writeln('handleMenu:['+ IntToStr(i) + ']' + p + ' :=: ' + v);

      str_html_shell := str_html_shell + p + ':=:' + v + #10;
    end;
  end;
  AResponse.Content :=  str_html_shell;
  AResponse.ContentType := c_texthtml; // Устанавливаем тип контента
  AResponse.SendResponse; // Отправляем ответ
end;

procedure TSimpleHTTPServer.handleMenu(var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);

  //**************************************
  //*  запросы управления меню
  //*
  //*  /meni?clear&caption1=Start network&cmd1=ifup can0&caption2=Stop network&cmd2=ifdown can0
  //**************************************
var
  i, j, idx: Integer;
  ParamName, ParamValue, s: string;
begin

  try
    for i := 0 to ARequest.QueryFields.Count - 1 do
    begin
      ParamValue := ARequest.QueryFields.ValueFromIndex[i];
      ParamName := ARequest.QueryFields.Names[i];
      if (length(ParamName) = 0)and(length(ParamValue) > 0) then
        ParamName := ParamValue;
      ParamName := UpperCase(ParamName);

      if ParamName = c_mnu_clear then
      begin
        for j := Config.getParamsCount() -1 downto 0 do
        begin
          ParamName := Config.params[j];
          if ParamName.StartsWith(Config.C_SEC_MENU) then
            Config.deleteParam(j);
        end;
      end
      else

      if ParamName = c_mnu_default then
      begin
        for j := Config.getParamsCount() -1 downto 0 do
        begin
          ParamName := Config.params[j];
          Config.deleteParam(j);
        end;
        Config.readConfigFile(Config.ini_filename);
      end
      else

      if Pos(c_mnu_cap, ParamName) = 1 then
      begin
        s := Copy(ParamName, length(c_mnu_cap)+1, Length(ParamName));
        idx := StrToIntDef(s, -1);
        if idx > 0 then
        begin
          s := Config.C_SEC_MENU + IntToStr(idx) + UpperCase(Config.C_PAR_MenuCaption);
          Config.asString[s] := ParamValue;
        end;
      end
      else

      if Pos(c_mnu_cmd, ParamName) = 1 then
      begin
        s := Copy(ParamName, length(c_mnu_cmd)+1, Length(ParamName));
        idx := StrToIntDef(s, -1);
        if idx > 0 then
        begin
          s := Config.C_SEC_MENU + IntToStr(idx) + UpperCase(Config.C_PAR_MenuCmd);
          Config.asString[s] := ParamValue;
        end;
      end;
    end;

    //AResponse.Content := 'ok';
    AResponse.Code := 200;
    AResponse.ContentType := c_texthtml;
    AResponse.SendResponse;
  finally
  end;
end;

procedure TSimpleHTTPServer.handleImageRequest(
  ARequest: TFPHTTPConnectionRequest; AResponse: TFPHTTPConnectionResponse;
  const aMime: String);
var
  Image: TPicture;
  Bitmap: TBitmap;
  Stream: TMemoryStream;
  NewWidth, NewHeight, i: Integer;
  s : string;
begin
  AResponse.ContentType := //'image/jpeg';
                         aMime;

  s := ARequest.URI;
  i := pos('?', s);
  if i > 0 then s := copy(s, 2, i-2);

  if not FileExists(s) then
  begin
    AResponse.Code:= 404;
    AResponse.SendContent;
    Exit;
  end;


  NewWidth := StrToIntDef(ARequest.QueryFields.Values['width'], 100); // Ширина по умолчанию 100
  NewHeight := StrToIntDef(ARequest.QueryFields.Values['height'], 100); // Высота по умолчанию 100

  Image := TPicture.Create;
  try
    Image.LoadFromFile(s);

    Bitmap := TBitmap.Create;
    try
      Bitmap.SetSize(NewWidth, NewHeight);
      Bitmap.Canvas.StretchDraw(Rect(0, 0, NewWidth, NewHeight), Image.Bitmap);

      Stream := TMemoryStream.Create;
      try
        Bitmap.SaveToStream(Stream);
        Stream.Position := 0;

        AResponse.ContentStream := Stream;
        AResponse.SendContent;
      finally
        Stream.Free;
      end;
    finally
      Bitmap.Free;
    end;
  finally
    Image.Free;
  end;
end;


procedure TSimpleHTTPServer.handleTHfile(aTHFN: String;
  var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
begin
  {
  тут нужны изменения:
    нужно определить файл ли это с нормального места или из какого то хранилища
    по префиксу.
    Например все имиджи будут храниться в расписанных стораджах, которые описаны в
    конфиге.

    поэтому нужно проверять в имени пути этакий префикс стораджа и поиск по нему


  Config.asString[Config.C_SEC_APP + Config.C_PAR_TH_DIR] +
  }

  read_thtml_from_file(str_html_shell, aTHFN);
  AResponse.Content :=      str_html_shell;
  setLength(str_html_shell, 0);

  AResponse.ContentType := c_texthtml; // Устанавливаем тип контента
  AResponse.SendResponse; // Отправляем ответ
end;

procedure TSimpleHTTPServer.handleUpload(
  var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
var
  wd, s, fn, sh,s1 : String;
  i : Integer;
begin
  s := '';
  wd := Config.asString[Config.C_SEC_APP + Config.C_PAR_WorkDir];
  wd := IncludeTrailingPathDelimiter(wd);

  for i := 0 to ARequest.Files.Count-1 do
  begin
    fn := ARequest.Files[i].FileName;
    //+ ' ' + inttostr(ARequest.Files[i].Size) + #13#10 ;
    fn := ExtractFileName(fn);
    if not DirectoryExists(wd +'.') then
      ForceDirectories(wd + '.');
    if not DirectoryExists(wd +'.') then
    begin
      Writeln('handleUpload:E: does not exist ' + wd);
      AResponse.Code:= 404;
      Exit;
    end;
    s := ExpandFileName(wd + fn);
    s1 := ARequest.Files[i].LocalFileName;
    //with TFileStream.Create(s, fmCreate) do
    //try
    //   CopyFrom(ARequest.Files[i].Stream, ARequest.Files[i].Size);
    //finally
    //  Free;
    //end;
    CopyFile(s1, s);
    Writeln(s1 + ' ==> ' + s);
    //DeleteFile(s1);
  end;

  //run the shell script aufter donwload
  s := ARequest.URI;
  i := pos('?', s);
  if i > 0 then
    s := copy(s, 1, i-1);

  i := ARequest.QueryFields.IndexOfName('path');
  if i >= 0 then
    s := ARequest.QueryFields.ValueFromIndex[i];


  Writeln('handleUpload:req:' + s);
  fn := 'upload.sh';
  //fn := ChangeFileExt(fn, '.sh');
  sh := Config.asString[Config.C_SEC_APP + Config.C_PAR_TH_DIR];
  sh := ExcludeTrailingPathDelimiter(sh);
  sh := IncludeTrailingPathDelimiter(sh +s);
  sh := ExpandFileName(sh + fn);
  Writeln('handleUpload:' + sh);
  if FileExists(sh) then
  begin
    if CommandExecutor.FIsRunning then
      CommandExecutor.StopCmd;
    s := ARequest.URI;
    if i > 0 then
      s := copy(s, i+1, length(s));
    sh := sh + ' "' + s + '"';
    strParams.change(sh);
    CommandExecutor.ExecCmd(sh);
  end
  else
    Writeln('upload.sh does not found!');


  AResponse.Content:= '{"message":"ok"}';
  AResponse.Code:= 200;
end;

function TSimpleHTTPServer.getIndexOfParams(aPar: string): Integer;
var
  i : Integer;
begin
  Result := -1;
  i := pos('=', aPar);
  if Result >= 0 then
  begin

  end;
end;

constructor TSimpleHTTPServer.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  strParams := TStrParamList.Create;
  strParams.init;
end;

destructor TSimpleHTTPServer.Destroy;
begin
  strParams.Free;
  inherited Destroy;
end;

procedure TSimpleHTTPServer.read_thtml_from_file(var aStr: String; aFileName: String);
begin
  aFileName :=  Config.asString[Config.C_SEC_APP + Config.C_PAR_TH_DIR] + aFileName + c_thtml;
  Writeln('read_thtml_from_file:' + aFileName);
  if FileExists(aFileName) then
  begin
    aStr:= ReadTextFileToString(aFileName);
    strParams.change(aStr);
  end;
end;

procedure TSimpleHTTPServer.init;
var
  i : Integer;
  s,p : String;
begin
  {$ifdef unix}
  thpath := '/var/techtool/thtml/';
  {$endif}
  {$ifdef windows}
  thpath := '.\';
  {$endif}

  Server.Port := 8080; // Устанавливаем порт
  if assigned(Config) then
  begin
    i := Config.asInt[Config.C_SEC_APP + Config.C_PAR_Port];

    if i > 0 then
      Server.Port := i;
    Writeln('shttps.init:port=' + IntToStr(Server.port));

    //correction of conf values
    p := Config.C_SEC_APP + Config.C_PAR_TH_DIR;
    s := Config.asString[p];
    i := length(s);
    if s[i] <> PathDelim then
    begin

      Config.asString[p] := s + PathDelim;
    end;
    p := Config.C_SEC_APP + Config.C_PAR_WorkDir;
    s := Config.asString[p];
    if s[length(s)] <> PathDelim then
    begin
      Config.asString[p] := s + PathDelim;

    end;
    //*

  end;



  Server.Threaded := True; // Включаем многопоточность
end;

function TSimpleHTTPServer.get_request_uri(const aURI: string): string;
begin
  Result := '/' + aURI;
end;

function TSimpleHTTPServer.is_request_uri_thtml(aURI: String;
  var aTHFN: String): Boolean;
var
  haveP: Integer;
  s : String;
begin
  Result := False;

  haveP := pos('?', aURI);
  if haveP < 1 then haveP := Length(aURI)+1;

  s := Config.asString[Config.C_SEC_APP + Config.C_PAR_TH_DIR];
  aURI := copy(aUri, 2, haveP -2);
  Writeln('is_request_uri_thtml : ' + aURI);

  aURI := ChangeFileExt(aURI, c_thtml);
  Result := FileExists(s + aURI);
  if Result then
    aTHFN:= ChangeFileExt(aURI, '');
end;

function TSimpleHTTPServer.is_request_uri_external_file(aURI: String;
  var aFN: String): Boolean;
var
  haveP: Integer;
  s : String;
begin
  Result := False;

  haveP := pos('?', aURI);
  if haveP < 1 then haveP := Length(aURI)+1;

  aURI := copy(aUri, 2, haveP -2);
  Writeln('is_request_uri_external_file : ' + aURI);

  if '.' + ExtractFileExt(aUri) = c_thtml then //Warning: how kind of ExtractFileExt(aUri)? with '.' or without?
    Exit;
  if ExtractFileExt(aUri) = c_thtml then //Warning: how kind of ExtractFileExt(aUri)? with '.' or without?
    Exit;

  Result := FileExists(aURI);
  if Result then
  begin
    aFN := aURI;
    Exit;
  end;

  s := Config.asString[Config.C_SEC_APP + Config.C_PAR_TH_DIR];
  Result := FileExists(s + aURI);
  if Result then
  begin
    aFN := aURI;
    Exit;
  end;
end;


//begin
//  Server := TSimpleHTTPServer.Create(nil); // Создаем HTTP-сервер
//  try
//    Server.Port := 8080; // Устанавливаем порт
//    Server.Threaded := True; // Включаем многопоточность
//    //WriteLn('HTTP-сервер запущен на порту 8080');
//    Server.Active := True; // Активируем сервер
//  finally
//    Server.Free; // Освобождаем ресурсы сервера
//  end;
end.
