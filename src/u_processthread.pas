unit u_processthread;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes;

type

  { T_ProcessThread }

  T_ProcessThread = class(TThread)
  private
    FTaskName: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const ATaskName: string; CreateSuspended: Boolean);
    destructor Destroy; override;
    class procedure FreeThread(var aThd: T_ProcessThread);
  end;

var
  ProcessThread : T_ProcessThread = nil;

implementation

uses
  u_CommandExecutor
  ;

{ T_ProcessThread }

constructor T_ProcessThread.Create(const ATaskName: string; CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FTaskName := ATaskName;
  FreeOnTerminate := False;
end;

destructor T_ProcessThread.Destroy;
begin
  WriteLn('Thread "', FTaskName, '" is being destroyed.');
  inherited Destroy;
end;

class procedure T_ProcessThread.FreeThread(var aThd: T_ProcessThread);
begin
  try
    aThd.Terminate;
    aThd.WaitFor;
    WriteLn('Thread stopped.');
  finally

    aThd.Free;
  end;
end;

procedure T_ProcessThread.Execute;
begin
  while not Terminated do
  begin

    //WriteLn('Thread "', FTaskName, '" is running...');
    CommandExecutor.GetText();


    Sleep(1000);
  end;
  WriteLn('Thread "', FTaskName, '" has finished.');
end;

end.

