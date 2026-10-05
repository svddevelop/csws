program simplyHTTPserver;

{$mode objfpc}{$H+}


uses
  {$ifdef UNIX}
    cthreads, cmem,
  {$endif}
  Classes, SysUtils, CustApp, crt,
  fphttpapp, httpdefs, httproute;


procedure route1(aReq: TRequest; aResp: TResponse);
begin
  aResp.content:='<html><body><h1>Route 1 The Default</h1></body></html>'
end;

procedure route2(aReq: TRequest; aResp: TResponse);
begin
  aResp.content:='<html><body><h1>Route 2</h1></body></html>'
end;

(*
begin
  HTTPRouter.registerRoute('/', @route1, true);
  HTTPRouter.registerRoute('/route2', @route2);
  Application.port := 8081;
  Application.threaded := true;
  Application.initialize;
  Application.run;
end.

*)

(*
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp
  , u_srvhttp2
  { you can add units after this };
*)
type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMyApplication }

const
   C_CTRL_C = #3;
procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
  key: AnsiChar;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }
//  THTTPServerApplication.runHHTPServerApplication(8081,  nil, nil );
  while true do
  begin
    if crt.KeyPressed then
    begin
      key := crt.ReadKey;
      //Writeln( ord(key) );
      if key = C_CTRL_C then
        Break;
      fphttpapp.Application.run;

    end;

  end;




  // stop program loop
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  //THTTPServerApplication.initHHTPServerApplication
end;

destructor TMyApplication.Destroy;
begin
  //THTTPServerApplication.doneHHTPServerApplication;
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  MyApplication: TMyApplication;
begin

  MyApplication:=TMyApplication.Create(nil);
  MyApplication.Title:='My Application';

  HTTPRouter.registerRoute('/', @route1, true);
  HTTPRouter.registerRoute('/route2', @route2);

  fphttpapp.Application.port := 8081;
  fphttpapp.Application.threaded := true;
  fphttpapp.Application.initialize;
  //fphttpapp.Application.run;


  MyApplication.Run;
//  fphttpapp.Application.free;
  MyApplication.Free;

end.

