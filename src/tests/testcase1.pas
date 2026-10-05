unit TestCase1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry;

type

  { TTestWebServ1 }

  TTestWebServ1= class(TTestCase)
  published
    procedure TestHookUp;
    procedure Test_CommandExecutor;
    procedure Test_WebServerCreation;

    procedure Test_getMenuList;
    procedure Test_Menu_clear_set_default;

    procedure TEST_SAFEMEMORYSTREAM;
    procedure Test_handleUpload;

    procedure Test_getImage;
  public
    procedure print_all_params_in_config;

  end;

implementation

uses
    u_TestCommandExecutor
  , u_CommandExecutor
  , u_SimpleHTTPServer
  , fphttpserver
  , u_conf
  , u_httpdefs
  , test_safememorystream

  ;

procedure TTestWebServ1.TestHookUp;
begin
  //Fail('Write your own test');
end;

procedure TTestWebServ1.Test_CommandExecutor;
begin
  doTest;
end;

procedure TTestWebServ1.Test_WebServerCreation;
begin
    CommandExecutor := TCommandExecutor.Create;
    Server := TSimpleHTTPServer.Create(nil); // Create the HTTP server
    try
      Server.init;
      Server.Active := True; // Activate the server
    finally
      Server.Free; // Release the server resources
      CommandExecutor.Free;
    end;
end;

procedure TTestWebServ1.Test_getMenuList;
const
  c_resp_menu_ok = 'DIR C:=:/shell?cmd=DIR C:\'#$0D#$0A
    +'WSL LS:=:/shell?cmd=wsl ls'#$0D#$0A
    +'DIR Z:=:/shell?cmd=dir /s Z:\tmp\'#$0D#$0A
    +'SYS:=:/system/test'#$0D#$0A'STOP:=:/stop'#$0D#$0A
    ;
var
  Request: TFPHTTPConnectionRequest;
  Response: T_Response;
  s : String;
begin
    Config := TConfig.Create;
    CommandExecutor := TCommandExecutor.Create;
    Server := TSimpleHTTPServer.Create(nil);
    Request := TFPHTTPConnectionRequest.Create;
    Response :=  T_Response.Create(Request);
    try
      Config.readConfigFile('.\csws.ini');
      Server.init;
      print_all_params_in_config();


      Response.Contents.Clear;
      server.handleMenulist(Request, TFPHTTPConnectionResponse(Response));
      s := Response.Content;
      AssertEquals(c_resp_menu_ok, s);

      WriteLn(s);
    finally
      Response.Free;
      Request.Free;
      Server.Free;
      CommandExecutor.Free;
      Config.Free;
    end;

end;

type T_HackRequest = class(TFPHTTPConnectionRequest);

procedure TTestWebServ1.Test_Menu_clear_set_default;
const
  c_url = '/menu?clear&caption1=Start network&cmd1=ifup can0&caption2=Stop network&cmd2=ifdown can0';
var
  Request: TFPHTTPConnectionRequest;
  HReq: T_HackRequest absolute Request;
  Response: T_Response;
  s : String;
  def_config_count, i: Integer;
begin
    Config := TConfig.Create;
    CommandExecutor := TCommandExecutor.Create;
    Server := TSimpleHTTPServer.Create(nil);
    Request := TFPHTTPConnectionRequest.Create;
    Response :=  T_Response.Create(Request);
    try
      Config.ini_filename:= '.\csws.ini';
      Config.readConfigFile(Config.ini_filename);
      Server.init;
      def_config_count := Config.getParamsCount();

      Writeln('old Config >>>');
      print_all_params_in_config();
      Writeln('<<');

      Request.URi:= c_url;
      Request.QueryFields.Add('clear');
      Request.QueryFields.Add('caption1=Start network');
      Request.QueryFields.Add('cmd1=ifup can0');
      Request.QueryFields.Add('caption2=Stop network');
      Request.QueryFields.Add('cmd2=ifdown can0');
      //T_HackRequest(Request).InitRequestVars;
      AssertEquals(5, Request.QueryFields.Count);

      //Response.Contents.Clear;
      server.handleMenu(Request, TFPHTTPConnectionResponse(Response));
      s := Response.Content;
      AssertEquals(Response.Code, 200);
      s := config.asString[Config.C_SEC_MENU+'1'+Config.C_PAR_MenuCaption];
      AssertEquals('Start network', s);
      s := config.asString[Config.C_SEC_MENU+'2'+Config.C_PAR_MenuCmd];
      AssertEquals('ifdown can0', s);
      Writeln('new Config >>>');
      print_all_params_in_config();
      Writeln('<<');

      Request.QueryFields.Clear;
      Request.QueryFields.Add('default');
      Response.Free;
      Response :=  T_Response.Create(Request);
      server.handleMenu(Request, TFPHTTPConnectionResponse(Response));
      Writeln('Config after default >>>');
      print_all_params_in_config();
      Writeln('<<');
      i := Config.getParamsCount();
      AssertEquals(def_config_count, i );


      WriteLn(s);
    finally
      Response.Free;
      Request.Free;
      Server.Free;
      CommandExecutor.Free;
      Config.Free;
    end;
end;

procedure TTestWebServ1.TEST_SAFEMEMORYSTREAM;
begin
  test__safememorystream_proc(Self);
end;

procedure TTestWebServ1.Test_handleUpload;
const
  c_resp_menu_ok = 'DIR C:=:/shell?cmd=DIR C:\'#$0D#$0A
    +'WSL LS:=:/shell?cmd=wsl ls'#$0D#$0A
    +'DIR Z:=:/shell?cmd=dir /s Z:\tmp\'#$0D#$0A
    +'SYS:=:/system/test'#$0D#$0A'STOP:=:/stop'#$0D#$0A
    ;
var
  Request: TFPHTTPConnectionRequest;
  Response: T_Response;
  Par_response: TFPHTTPConnectionResponse absolute Response;
  s,fn : String;
  i : Integer;
  st: TStream;
begin
    Config := TConfig.Create;
    CommandExecutor := TCommandExecutor.Create;
    Server := TSimpleHTTPServer.Create(nil);
    Request := TFPHTTPConnectionRequest.Create;

    Request.URI:= '/upload?param1=1&param2=$(COMPUTERNAME)';
    i := Request.Files.count;
    Request.Files.Add;
    Request.Files[i].FileName:='aa.txt';
    //Request.Content.Compare();
    st := Request.Files[i].Stream;
    st.WriteAnsiString('12345');

    Response :=  T_Response.Create(Request);
    try
      Config.readConfigFile('.\csws.ini');
      Server.init;
      print_all_params_in_config();


      Response.Contents.Clear;
      server.handleUpload(Request, Par_response);



      s := Response.Content;
      AssertEquals(c_resp_menu_ok, s);

      fn := Config.asString[Config.C_SEC_APP+Config.C_PAR_WorkDir];
      fn += '\aa.txt';
      //s := TFile.readalltext(fn);
      with tstringlist.create do try loadfromfile(fn);s := Text;finally free; end;
      AssertEquals('12345', s);

      WriteLn(s);
    finally
      Response.Free;
      Request.Free;
      Server.Free;
      CommandExecutor.Free;
      Config.Free;
    end;
end;

type  T_Request = class(TFPHTTPConnectionRequest)
  public
    procedure initVars;
  end;
procedure T_Request.initVars;
begin
    //InitGetVars;
    ProcessQueryString(QueryString, QueryFields);
end;

procedure TTestWebServ1.Test_getImage;

const
    c_resp_menu_ok = 'DIR C:=:/shell?cmd=DIR C:\'#$0D#$0A
      +'WSL LS:=:/shell?cmd=wsl ls'#$0D#$0A
      +'DIR Z:=:/shell?cmd=dir /s Z:\tmp\'#$0D#$0A
      +'SYS:=:/system/test'#$0D#$0A'STOP:=:/stop'#$0D#$0A
      ;
var
    Request: T_Request;
    Response: T_Response;
    Par_Response: TFPHTTPConnectionResponse absolute Response;
    Par_Request: TFPHTTPConnectionRequest absolute Request;
    s,fn : String;
    i : Integer;
    //st: TStream;
begin
      Config := TConfig.Create;
      CommandExecutor := TCommandExecutor.Create;
      Server := TSimpleHTTPServer.Create(nil);
      Request := T_Request.Create;

      s := ExtractFilePath(ParamStr(0))
           + '..' + PathDelim+'..' + PathDelim + 'src' + PathDelim+'tests'+PathDelim
           + 'IMG_20241218_203504.jpg';
      s := ExpandFileName(s);
      //full path to test file, how need to request

      s := '/' + s + '?width=30&height=30';

      Request.URI:= s;
      Request.InitVars;
      //i := Request.Files.count;
      //Request.Files.Add;
      //Request.Files[i].FileName:='aa.txt';
      //Request.Content.Compare();
      //st := Request.Files[i].Stream;
      //st.WriteAnsiString('12345');

      Response :=  T_Response.Create(Request);
      try
        Config.readConfigFile('.\csws.ini');
        Server.init;
        print_all_params_in_config();


        Response.Contents.Clear;
        server.HandleRequest(Par_Request, Par_response);



        s := Response.Content;
        AssertEquals(c_resp_menu_ok, s);

        fn := Config.asString[Config.C_SEC_APP+Config.C_PAR_WorkDir];
        fn += '\aa.txt';
        //s := TFile.readalltext(fn);
        //with tstringlist.create do try loadfromfile(fn);s := Text;finally free; end;
        AssertEquals('12345', s);

        WriteLn(s);
      finally
        Response.Free;
        Request.Free;
        Server.Free;
        CommandExecutor.Free;
        Config.Free;
      end;
end;

procedure TTestWebServ1.print_all_params_in_config;
var
  i : Integer;
  s : String;
begin
  for i := 0 to Config.getParamsCount() -1 do
  begin
    s := Config.params[i];
    WriteLn(s + ' = ' + Config.asString[s]);

  end;
end;



initialization

  RegisterTest(TTestWebServ1);
end.

