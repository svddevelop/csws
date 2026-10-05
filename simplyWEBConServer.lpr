program simplyWEBConServer;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, fphttpapp, fphttpserver, httpdefs, httproute, process,
  StringStack, CommandExecutor;


type
  TIsTrminatedSimple = function(): Boolean;
  TIsTrminatedObject = function(): Boolean of object;

var
  isTerminatedS : TIsTrminatedSimple = nil;

  cmdProcess : TProcess;


procedure HandleRequest(ARequest: TRequest; AResponse: TResponse);
var
  Command, Output: string;
  Process: TProcess;

  //function is_terminated:Boolean;
  //begin
  //  Result := Assigned(isTerminatedS);
  //  if Result then
  //    Result := isTerminatedS();
  //end;

begin
  // Get the command from the request parameter
  Command := ARequest.QueryFields.Values['cmd'];

  if Command = '' then
  begin
    AResponse.Content := 'Usage: Pass a command using the "cmd" query parameter.';
    AResponse.ContentType := 'text/plain';
    AResponse.SendResponse;
    Exit;
  end;

  // Execute the command
  //Process := TProcess.Create(nil);
  try
    cmdProcess.Executable := 'cmd.exe';//'/bin/sh';
    cmdProcess.Parameters.Add('-c');
    cmdProcess.Parameters.Add(Command);
    cmdProcess.Options := [poUsePipes, {poStderrToOutPut,}poNoConsole];
    cmdProcess.Execute;

    // Read the output of the command
    Output := '';
    while cmdProcess.Output.NumBytesAvailable > 0 do
    begin
      //if is_terminated() then
      //   Break;

      SetLength(Output, Length(Output) + cmdProcess.Output.NumBytesAvailable);
      cmdProcess.Output.ReadBuffer(Output[Length(Output) - cmdProcess.Output.NumBytesAvailable + 1], cmdProcess.Output.NumBytesAvailable);
    end;

//    cmdProcess.WaitOnExit;

    // Return the result to the client
    AResponse.Content := '<pre>' + Output + '</pre>';
    AResponse.ContentType := 'text/html';
    AResponse.SendResponse;
  finally
    //cmdProcess.Free;
  end;
end;

begin
  Application.Port := 8080;
  HTTPRouter.RegisterRoute('*', @HandleRequest);
  Application.Initialize;

  cmdProcess := TProcess.Create(nil);

  try
    Application.Run;

  finally
    cmdProcess.Free;
  end;
end.
