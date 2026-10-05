unit u_TestCommandExecutor;

interface

uses
  u_CommandExecutor, Classes, SysUtils;

var
  CommandExecutor: TCommandExecutor;
  Thread1, Thread2: TThread;


type
  TTestThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure doTest;

implementation



procedure TTestThread.Execute;
var
  s : String;
begin
  // Execute the command
  if not CommandExecutor.IsRunning then
    CommandExecutor.ExecCmd('echo Hello from Thread ' + IntToStr(Self.ThreadID));
  Sleep(100); // Emulate a delay
  // Get the output of the command
  s := CommandExecutor.GetText;
//  WriteLn(s);
end;

procedure doTest;
begin
  CommandExecutor := TCommandExecutor.Create;
  try
    // Create two threads for the testing
    Thread1 := TTestThread.Create(False);
    Thread2 := TTestThread.Create(False);

    // Wait for the threads to finish
    Thread1.WaitFor;
    Thread2.WaitFor;

    // Free the threads
    Thread1.Free;
    Thread2.Free;
  finally
    CommandExecutor.Free; // Free the CommandExecutor
  end;
end;

end.

