unit u_srvhttp2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, custhttpapp, u_ownlogger, HTTPDefs;

type

  { THTTPServerApplication }

  { TWebServerThread }

  TWebServerThread = class(TThread)
    class function CreateAnonymousThread(aProc: TProcedure): TWebServerThread;static;
  end;

  THTTPServerApplication = class(TCustomHTTPApplication)
    public
      type
          THTTPServerDoRunCheck= procedure(Sender: TObject);
          THTTPServerObjDoRunCheck= procedure(Sender: TObject) of object;
    private
      FOnHTTPServerDoRunCheck: THTTPServerDoRunCheck;
      FOnHTTPServerObjDoRunCheck: THTTPServerObjDoRunCheck;
      class var WebServerThread: TWebServerThread;
      procedure WebHandlerIdle(Sender: TObject);

      //class procedure DoError(AResponse: TResponse; AnException: Exception; var handled: boolean);
      Procedure DoRequestError(Sender : TObject; E : Exception);
      Procedure beforeRouterRequest(Sender : TObject; ARequest : TRequest; AResponse : TResponse);
      Procedure DoServerRequestError(Sender : TObject; E : Exception);
    public
      Procedure Terminate;override;
      procedure DoRun; override;
      property OnHTTPServerDoRunCheck: THTTPServerDoRunCheck read FOnHTTPServerDoRunCheck write FOnHTTPServerDoRunCheck;
      property OnHTTPServerObjDoRunCheck: THTTPServerObjDoRunCheck read FOnHTTPServerObjDoRunCheck write FOnHTTPServerObjDoRunCheck;
    public
      class var  HTTPServerApplication: THTTPServerApplication;
      class var ShowCleanUpErrors : Boolean;
      class procedure initHHTPServerApplication;
      class procedure doneHHTPServerApplication;
      class procedure runHHTPServerApplication(aPort: Word; aOnHTTPServerDoRunCheck: THTTPServerDoRunCheck = nil; aOnHTTPServerObjDoRunCheck: THTTPServerObjDoRunCheck = nil);
  end;

implementation

uses
  {$ifdef UNIX}
  cthreads, cmem,
  {$endif}
  crt,
  {fphttpapp}custapp, httproute, {u_conf,} u_srvhttp2_route, fphttpserver;

{ TWebServerThread }

class function TWebServerThread.CreateAnonymousThread(aProc: TProcedure): TWebServerThread;
var
   tobj: TThread;
   wst : TWebServerThread absolute tobj;
begin
  tobj := TThread.CreateAnonymousThread(aProc);
  Result := wst;
end;

{ THTTPServerApplication }

procedure THTTPServerApplication.WebHandlerIdle(Sender: TObject);
begin
  if Assigned(FOnHTTPServerDoRunCheck) then
    try
      FOnHTTPServerDoRunCheck(Self);
    except on E: Exception do
      Debugln( 'THTTPServerApplication.WebHandlerIdle[' + IntToHex(int64(Self))
               + '](1):' + E.Message);
    end;
  if Assigned(FOnHTTPServerObjDoRunCheck) then
    try
      FOnHTTPServerObjDoRunCheck(Self);
    except on E: Exception do
    Debugln( 'THTTPServerApplication.WebHandlerIdle[' + IntToHex(int64(Self))
             + '](2):' + E.Message);
    end;
end;

procedure THTTPServerApplication.DoRequestError(Sender: TObject; E: Exception);
var
  s : String;
begin
  s := 'THTTPServerApplication.DoRequestError:' + ' E:'  + E.Message;
  Writeln( s );
  DebugLn( s );
end;

procedure THTTPServerApplication.beforeRouterRequest(Sender: TObject;ARequest: TRequest; AResponse: TResponse);
var
   s : String;
begin
   s := 'aRequest.URL:';
   s := s + ARequest.URL;
   Writeln( s );
   DebugLn('THTTPServerApplication.beforeRouterRequest:' + s );
end;

procedure THTTPServerApplication.DoServerRequestError(Sender: TObject;E: Exception);
var
  s : String;
begin
  s := 'THTTPServerApplication.DoServerRequestError:' + ' E:'  + E.Message;
  Writeln( s );
  DebugLn( s );
end;

procedure DoError(AResponse: TResponse; AnException: Exception; var handled: boolean);
begin
  handled:= True;
  DebugLn('DoError: Req:' + AResponse.Request.URL+ ' E:'  +AnException.Message );
end;

type THachServer = class(TFPCustomHttpServer);

procedure THTTPServerApplication.Terminate;
var
  ehs: TEmbeddedHttpServer;
  hs : THachServer absolute ehs;
begin
  ehs := Self.HTTPHandler.HTTPServer;
  hs.active := False;
  inherited;
end;

procedure THTTPServerApplication.DoRun;
begin
//  inherited DoRun;
  WebHandler.Run;
end;

class procedure THTTPServerApplication.initHHTPServerApplication;
begin
  ShowCleanUpErrors := False;
  HTTPServerApplication := THTTPServerApplication.Create(Nil);
//  if not assigned(CustomApplication) then
//    CustomApplication := HTTPServerApplication;
end;

class procedure THTTPServerApplication.doneHHTPServerApplication;
begin
  if CustomApplication=HTTPServerApplication then
    CustomApplication := nil;
  try
    FreeAndNil(HTTPServerApplication);
  except
    if ShowCleanUpErrors then
      Raise;
  end;
end;

type THackThread = class(TThread);

procedure AppStart;
begin
  while not THTTPServerApplication.WebServerThread.Terminated do
    //if assigned(THTTPServerApplication) then
      if assigned(THTTPServerApplication.HTTPServerApplication) then
        THTTPServerApplication.HTTPServerApplication.Run;
end;

procedure DoShowRequestException(AResponse: TResponse; AnException: Exception; var handled: boolean);
begin
  handled:=True;
end;

type THackHTTPServer = class(TEmbeddedHttpServer);

class procedure THTTPServerApplication.runHHTPServerApplication(aPort: Word; aOnHTTPServerDoRunCheck: THTTPServerDoRunCheck = nil; aOnHTTPServerObjDoRunCheck: THTTPServerObjDoRunCheck = nil);
var
  ehs: TEmbeddedHttpServer;
  hehs: THackHTTPServer absolute ehs;
begin
  HTTPRouter.RegisterRoute('/', @route1, true);
  HTTPRouter.RegisterRoute('/2', @route2);
  //HTTPRouter.RegisterRoute('/favicon.ico', @route1);

  //HTTPRouter.Method := [rmUnknown,rmAll,rmGet,rmPost,rmPut,rmDelete,rmOptions,rmHead, rmTrace];
  HTTPRouter.BeforeRequest:= @beforeRouterRequest;


  HTTPServerApplication.Port := aPort;
  HTTPServerApplication.OnHTTPServerDoRunCheck := aOnHTTPServerDoRunCheck;
  HTTPServerApplication.OnHTTPServerObjDoRunCheck := aOnHTTPServerObjDoRunCheck;
  //HTTPServerApplication.WebHandler.OnIdle := @HTTPServerApplication.WebHandlerIdle;
  HTTPServerApplication.OnShowRequestException := @DoError;
  HTTPServerApplication.Threaded := true;
  HTTPServerApplication.Initialize;

  HTTPServerApplication.HTTPHandler.OnRequestError := @DoRequestError;
  HTTPServerApplication.HTTPHandler.OnShowRequestException:= @DoShowRequestException;
  ehs := HTTPServerApplication.HTTPHandler.HTTPServer;
  hehs.OnRequestError := @DoServerRequestError;

  //HTTPServerApplication.OnAcceptIdle := @HTTPServerApplication.WebHandlerIdle;
  //HTTPServerApplication.;
 // HTTPServerApplication.Run;

  WebServerThread := TWebServerThread(TWebServerThread.CreateAnonymousThread(@AppStart));
  WebServerThread.Start;

  WriteLn('Press any key to shutdown...');
  ReadKey;
  //HTTPServerApplication.HTTPHandler.HTTPServer.;

  hehs.Active:= False;
  WebServerThread.Terminate;
  WriteLn('WebServer thread ended.');
  //HTTPServerApplication.Terminate;
  doneHHTPServerApplication;
end;

end.

