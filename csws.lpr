program csws;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp , LCLType

  , u_CommandExecutor
  , u_SimpleHTTPServer
  , u_strparams
  , u_conf
  , u_httpclient
  , u_versionsinfo
  , u_safememorystream
  , u_processthread
  , u_objhelper, u_mime_types
  , u_sceduler
  { you can add units after this };

const
  {$ifdef windows}
  C_LOG_FILE = '.\csws.log';
  {$endif}
  {$ifdef unix}
  C_LOG_FILE = '/tmp/csws.log';
  {$endif}

type

  { TSimpleWebServer }

  TSimpleWebServer = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    procedure WriteHelp; virtual;
    function check_addmenu(): Boolean;
    function check_externalcfg(): Boolean;
    function check_sced(): Boolean;
  public const
    C_IP_DELIMITER = ':=:';
    C_IP_ADDMENU = 'addmenu';
    C_IP_EXTCFG = 'conf';
    C_IP_SCEDULER = 'sceduler';
    C_IP_SCEDNEW = 'scednew';
    C_IP_SCEDDEL = 'sceddel';
    C_IP_SCEDLIST = 'scedlist';
    C_IP_SCEDON = 'scedon';
    C_IP_SCEDOFF = 'scedoff';
  end;

const
   C_help =
        'Usage: '#13#10
       +' --help'#13#10
       +' --addmenu="<menu caption>'+TSimpleWebServer.C_IP_DELIMITER+'<command>" ::'
       +' add new command to configurations file;'#13#10
       +' --conf="/home/technik/mypersonalconfiguration.conf" :: run with own configuration;'#13#10
       +' --stop :: stop the running application;'#13#10
       +' --envvar :: shows all possibles environmen variables;'#13#10
       +''#13#10

       +'Scheduler options:'#13#10
       +' --sceduler :: run the task scheduler together with the web server;'#13#10
       +' --scednew="<name>'+TSimpleWebServer.C_IP_DELIMITER+'<command>'+TSimpleWebServer.C_IP_DELIMITER+'<period>" ::'
       +' create a new schedule (command and period are optional);'#13#10
       +' --sceddel="<name>" :: delete the schedule with its section;'#13#10
       +' --scedlist :: show all schedules with period, last run and next run;'#13#10
       +' --scedon="<name>" :: activate the schedule (add the name to [scedule]);'#13#10
       +' --scedoff="<name>" :: deactivate the schedule (remove the name from [scedule]);'#13#10
       +''#13#10
       +'Schedule configuration:'#13#10
       +' [scedule] :: list of the active schedules, one entry per line as <name>=1;'#13#10
       +' [scedule.<name>] :: section of one schedule;'#13#10
       +'   Command -- the command which must be executed;'#13#10
       +'   Period  -- how often to run: 30s, 15m, 1h, 1h30m, 1d,'#13#10
       +'              daily, weekly, daily at=03:00, weekly at=22:30;'#13#10
       +'   LastRun -- date and time of the last run, empty = never run;'#13#10
       +''#13#10

       +'HTML references:'#13#10
       +' /shell?cmd=python myownprg.py :: executed the command and shows output in the browser;'#13#10
       +' /shellbreak :: break the execution of command;'#13#10
       +' /stop  :: finished the application;'#13#10
       +' /menulist :: responsed with menu list;'#13#10
       +' /addenvvar?my_envvar=value  :: add or replace the value of the environment variable;'#13#10
       +' /menu?clear&caption1=menu1&cmd1=do1.sh&caption2=menu2&cmd2=do2.sh&default :: possibility to change menu;'#13#10
       +''#13#10
     ;

{ TSimpleWebServer }

procedure TSimpleWebServer.DoRun;
var
  i : Integer;
  ScThread: TThdSceduler;
//  s,p, ErrorMsg: String;
begin
  // quick check parameters
  //ErrorMsg:=CheckOptions('h', 'help');
  //if ErrorMsg<>'' then
  //begin
  //  ShowException(Exception.Create(ErrorMsg));
  //  Terminate;
  //  Exit;
  //end;

  try
  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;
  if HasOption('s', 'stop') then
  begin
    u_httpclient.SendHttpRequest('http://127.0.0.1/stop');
    Terminate;
    Exit;
  end;

  if HasOption('e', 'envvar') then
  begin
    with TStrParamList.Create do
    try
      init;
      for i := 0 to count-1 do
        writeln(Strings[i]);
    finally
      free;
    end;
    Terminate;
    Exit;
  end;

  Config := TConfig.Create;
  if check_externalcfg() then
  begin
    Terminate;
    Config.Free;
    Exit;
  end
  else
  begin
    if FileExists(TConfig.ini_filename) then
       Config.readConfigFile(Config.ini_filename);
  end;

  if check_sced() then
  begin
    Terminate;
    Config.Free;
    Exit;
  end;

  if check_addmenu() then
  begin
    Terminate;
    Config.Free;
    Exit;
  end;

  SafeMemoryStream := TSafeMemoryStream.Create;
  ProcessThread := T_ProcessThread.Create('a', true);
  CommandExecutor := TCommandExecutor.Create;
  ProcessThread.Start;
  Server := TSimpleHTTPServer.Create(nil); // create the HTTP server
  ScThread := nil;
  try
    Server.ResourceInstance :=  Self;
    if FileExists(Config.ini_filename) then
       Config.readConfigFile(Config.ini_filename);
    // start the task scheduler if --sceduler was given
    if HasOption(C_IP_SCEDULER) then
      ScThread := TThdSceduler.Create(False);
    Server.init;
    Server.Active := True; // activate the server
  finally
    if Assigned(ScThread) then
    begin
      ScThread.Terminate;
      ScThread.WaitFor;
      ScThread.Free;
    end;
    Server.Free; // release the server resources
    T_ProcessThread.FreeThread(ProcessThread);
    CommandExecutor.Free;
    Config.Free;
    SafeMemoryStream.Free;
  end;


  // stop program loop
  Terminate;
  except
    // DoRun is called in a loop by TCustomApplication.Run, so every error
    // must terminate the application instead of being repeated forever
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Terminate;
    end;
  end;
end;

procedure TSimpleWebServer.WriteHelp;
begin
    Writeln(C_help);
end;

function TSimpleWebServer.check_addmenu(): Boolean;
var
  s : String;
  sa: TStringArray;
begin
  //s:=CheckOptions(C_IP_ADDMENU, C_IP_ADDMENU);
  //if s<>'' then
  //begin
  //  ShowException(Exception.Create(s));
  //
  //  Exit(true);
  //end;

  Result := HasOption(C_IP_ADDMENU);
  if Result then
  begin
    //--addmenu="<caption>:=:<command>"
    s := GetOptionValue(C_IP_ADDMENU);
    sa := s.Split([C_IP_DELIMITER]);
    if length(sa) > 1 then
    begin
      if not FileExists(Config.ini_filename) then
        Config.makeConfigFile(Config.ini_filename);

      Config.readConfigFile(Config.ini_filename);
      Config.addmenu(sa[0], sa[1]);
      //Config.writeConfigFile(Config.ini_filename);
    end
    else
      WriteLn('it must be as --addmenu="<caption>:=:<command>"');
  end;
end;

function TSimpleWebServer.check_externalcfg(): Boolean;
var
  s : String;
begin
  //s:=CheckOptions(C_IP_EXTCFG, C_IP_EXTCFG);
  //if s<>'' then
  //begin
  //  ShowException(Exception.Create(s));
  //
  //  Exit(true);
  //end;

  Result := HasOption(C_IP_EXTCFG);
  if Result then
  begin
    s := GetOptionValue(C_IP_EXTCFG);
    Result := FileExists(s);
    //if Result then
    begin
      TConfig.ini_filename:= s;
      Result := False;
    end;

  end;
end;

function TSimpleWebServer.check_sced(): Boolean;
var
  s: String;
  sa: TStringArray;
  scName: String;
begin
  // manage the schedules and exit: --scednew, --sceddel, --scedlist,
  // --scedon, --scedoff
  Result := HasOption(C_IP_SCEDLIST)
      or HasOption(C_IP_SCEDNEW)
      or HasOption(C_IP_SCEDDEL)
      or HasOption(C_IP_SCEDON)
      or HasOption(C_IP_SCEDOFF);
  if not Result then Exit;

  if not FileExists(Config.ini_filename) then
    Config.makeConfigFile(Config.ini_filename);

  if HasOption(C_IP_SCEDLIST) then
    ScedList;

  if HasOption(C_IP_SCEDNEW) then
  begin
    //--scednew="<name>" or --scednew="<name>:=:<command>:=:<period>"
    s := GetOptionValue(C_IP_SCEDNEW);
    sa := s.Split([C_IP_DELIMITER]);
    case length(sa) of
      0: WriteLn('it must be as --scednew="<name>'+C_IP_DELIMITER+'<command>'+C_IP_DELIMITER+'<period>"');
      1: ScedNew(sa[0], '', '');
      2: ScedNew(sa[0], sa[1], '');
      else ScedNew(sa[0], sa[1], sa[2]);
    end;
  end;

  if HasOption(C_IP_SCEDDEL) then
    ScedDelete(GetOptionValue(C_IP_SCEDDEL));

  if HasOption(C_IP_SCEDON) then
  begin
    scName := GetOptionValue(C_IP_SCEDON);
    ScedActivate(scName);
  end;

  if HasOption(C_IP_SCEDOFF) then
  begin
    scName := GetOptionValue(C_IP_SCEDOFF);
    ScedDeactivate(scName);
  end;
end;




var
  Application: TSimpleWebServer;
  //OutputFile: Text;
  OutputBuf: array of byte;
  doDbgLog: Boolean = false;
  SL: TStringList;
  s1, s2 : String;


{$R *.res}

begin
  //doDbgLog := not FindCmdLineSwitch('debug', true);



  //if TSimpleWebServer(nil).HasOption('d','debug') then doDbgLog := false;
  if doDbgLog then
  begin
    Flush(Output);
    Close(Output);
    Flush(ErrOutput);
    Close(ErrOutput);
    SetTextBuf(Output, OutputBuf, 0);
    SetTextBuf(ErrOutput, OutputBuf, 0);
    Assign(Output, C_LOG_FILE);
    Assign(ErrOutput, C_LOG_FILE);
  end;
  try
    if doDbgLog then
    begin
      Rewrite(Output);
      //Rewrite(ErrOutput);
      Writeln('start log');
      Flush(Output);
    end;

    SL:= TStringList.Create;
    try

      ReadVersionInfoParams(System.HINSTANCE, SL);
      s1 :=
           SL.Values['LegalCopyright'] + #13#10
         + SL.Values['Comments'] + #13#10
         + SL.Values['ProductName'] + ' ver. ' + SL.Values['FileVersion'] + #13#10

      ;
      Writeln(s1);

    finally
      SL.Free;
    end;



    Application:=TSimpleWebServer.Create(nil);
    Writeln('App run');
    Flush(Output);
    Application.Title:='Simple Web Server';
    Application.Run;

  finally
    Flush(ErrOutput);
    Writeln('App finally');
    Flush(Output);
    Application.Free;
    Writeln('App end');
    //CloseFile(OutputFile);
    if doDbgLog then
    begin
      Flush(Output);
      Close(Output);
      Assign(Output, '');
      Rewrite(Output);
      Flush(ErrOutput);
      Close(ErrOutput);
      Assign(ErrOutput, '');
      Rewrite(ErrOutput);
    end;
  end;
end.

