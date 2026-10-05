program verysimplewebserver;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp

  , fphttpapp, httproute, httpdefs, fphttp, fpwebfile
  { you can add units after this };




procedure HandleRootRequest(ARequest: TRequest; AResponse: TResponse);
var
  s : string;
  i : Integer;
begin
  s := '';
//  for i := 0 to ARequest.Files.Count-1 do
//    s += ARequest.Files[i].FileName + ' ' + inttostr(ARequest.Files[i].Size) + #13#10 ;

  s := ARequest.Content;
  ARequest.QueryFields.text := s;
  ARequest.QueryFields.SaveToFile('files.txt');



  AResponse.Content := '<html><body><h1>Hello, World!</h1></body></html>';
  AResponse.ContentType := 'text/html';
  AResponse.SendResponse;
end;

procedure HandleEchoRequest(ARequest: TRequest; AResponse: TResponse);
var
  Name: string;
begin


  Name := ARequest.QueryFields.Values['name'];
  if Name = '' then
    Name := 'Guest';

  AResponse.Content := '<html><body><h1>Hello, ' + Name + '!</h1></body></html>';
  AResponse.ContentType := 'text/html';
  AResponse.SendResponse;
end;

begin
  // Set up the port and the host
  Application.Port := 8880;
  Application.Address := '0.0.0.0'; // Listen on all interfaces

  // Register the routes
  HTTPRouter.RegisterRoute('*', @HandleRootRequest);
  HTTPRouter.RegisterRoute('/echo', @HandleEchoRequest);

  // Start the server
  WriteLn('Starting web server on http://', Application.Address, ':', Application.Port);
  Application.Threaded := False; // Single threaded mode
  Application.Initialize;
  Application.Run;
end.

