unit u_CommandExecutor;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SyncObjs, Pipes;

type
  TCommandExecutor = class
  private
    FCmdProcess: TProcess;

    FCriticalSection: TCriticalSection;
  public
    FIsRunning: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExecCmd(const ACommand: string);
    procedure StopCmd;
  function GetText: string;
    function IsRunning: Boolean;
  end;

var
  CommandExecutor: TCommandExecutor;

implementation

uses
    SysUtils
  , u_safememorystream
  ;

constructor TCommandExecutor.Create;
begin
  inherited Create;
  FCmdProcess := TProcess.Create(nil);
  FCmdProcess.Options := [poUsePipes, poStderrToOutPut];
  FCmdProcess.ShowWindow := swoHIDE;

  FCriticalSection := TCriticalSection.Create;
  FIsRunning := False;
end;

destructor TCommandExecutor.Destroy;
begin
  if FIsRunning then
  begin

    FCmdProcess.Terminate(0);
  end;
  FCmdProcess.Free;

  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TCommandExecutor.ExecCmd(const ACommand: string);
begin
  Writeln('ExecCmd:criticalsec');
  FCriticalSection.Enter;
  try
    if FIsRunning then
      exit;//raise Exception.Create('Another command is already running.');

    Writeln('ExecCmd:'+ACommand);

    FCmdProcess.Executable := '/bin/sh';
    {$IFDEF WINDOWS}
    FCmdProcess.Executable := 'cmd.exe';
    {$ENDIF}
    FCmdProcess.Parameters.Clear;
    {$IFDEF WINDOWS}
    FCmdProcess.Parameters.Add('/c');
    {$ENDIF}
    {$IFDEF LINUX}
    FCmdProcess.Parameters.Add('-c');
    {$ENDIF}
    FCmdProcess.Parameters.Add(ACommand);

    FCmdProcess.Execute;
    FIsRunning := True;
  finally
    FCriticalSection.Leave;
  end;
  Writeln('ExecCmd:END');
end;

procedure TCommandExecutor.StopCmd;
begin
  Writeln('StopCmd:criticalsec');
  FCriticalSection.Enter;
  try

    if FIsRunning then
    begin
      Writeln('StopCmd:Terminate');
      FCmdProcess.Terminate(0);
      FCmdProcess.WaitOnExit;
      Writeln('StopCmd:after WaitOnExit');
      FIsRunning := False;
    end;
  finally
    FCriticalSection.Leave;
  end;
  Writeln('StopCmd:END');
end;

function TCommandExecutor.GetText: string;
var
  BytesRead: LongInt;
  Buffer: array[1..2048] of Byte;
  OutputString: string;
begin
  Result := '';
  //Writeln('CE.GetText:BEGIN');
  FCriticalSection.Enter;
  try

    if not assigned( FCmdProcess.Output) then Exit;

    Sleep(10);

    //Writeln('CE.GetText:before read');
    while FCmdProcess.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := FCmdProcess.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
      begin
        Writeln('CE.GetText: read ' + IntTostr(BytesRead));
        SetLength(OutputString, BytesRead);
        Move(Buffer[1], OutputString[1], BytesRead);

        SafeMemoryStream.PushRawByteString(OutputString);
      end;

      //Writeln('CE.GetText:after read');
    end;

    if FIsRunning and (not FCmdProcess.Running) then
    begin
      FIsRunning := False;
      //Writeln('CE.GetText:before WaitOnExit');
      FCmdProcess.WaitOnExit;
    end;

    //Writeln('CE.GetText:before Text');
    //Result := FOutputBuffer.Text;
    //Writeln('CE.GetText:after Text');
    //FOutputBuffer.Clear;
    //Writeln('CE.GetText:after Clear');
  finally
    FCriticalSection.Leave;
  end;
  //Writeln('CE.GetText:END');
end;

function TCommandExecutor.IsRunning: Boolean;
begin
  FCriticalSection.Enter; // Enter the critical section
  try
    Result := FIsRunning; // Return the running state
  finally
    FCriticalSection.Leave; // Leave the critical section
  end;
end;

end.
