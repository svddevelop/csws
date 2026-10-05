unit u_ownlogger;

{$mode objfpc}{$H+}

interface

uses
  //LazLogger,
  Classes, SysUtils;

procedure LazLoggerUseStdOut( value: Boolean);
procedure DebugLn(aStr: String);

implementation

uses
  Semaphore
  ;

var
  UseStdOut : Boolean = False;
  log_sem : TSemaphore;
  log_fn: String = '';
  log_fs : TFilestream = nil;

procedure open_FS;
begin
  log_fs := TFileStream.Create( log_fn, fmOpenWrite + fmShareDenyWrite);
  log_fs.Seek( 0, soEnd );
end;

procedure write_log_to_file(aMsg: String);
begin
  if assigned( log_fs ) then
     begin
       log_fs.Seek(0, soEnd);
       log_fs.Write( pointer(aMsg + #13#10)^, length(aMsg) +2);
     end;
end;

procedure LazLoggerUseStdOut(value: Boolean);
begin
  {$ifdef windows}
  //LazLogger.DebugLogger.UseStdOut := Value;
  UseStdOut := Value;
  {$else}
  UseStdOut := Value;
  {$endif}
end;

procedure DebugLn(aStr: String);
var
  s : String;
begin
  while log_sem.Used do
    Sleep(10);
  log_sem.Wait;
  try

    s := FormatDateTime('d HH:nn:ss.zzz ', Now) + aStr;
    {$ifdef windows}
    //DebugLn( s + aStr );
    write_log_to_file( s );
    if UseStdOut then
      Writeln( s );
    {$else}
    write_log_to_file( s );
    if UseStdOut then
      Writeln( s );
    {$endif}

  finally
     log_sem.Post;
  end;
end;

procedure find_log_file;
var
  s : String;
  i,j : Integer;
begin
  if FindCmdLineSwitch('debug-log') then
  begin
    for i := 1 to ParamCount do
    begin
      s := ParamStr(i);
      j := pos('debug-log=', s);
      if j > 0 then
      begin
        log_fn := copy(s, j + 10);
        if not FileExists( log_fn ) then
        try
          with TFileStream.Create( log_fn, fmCreate) do
          try
          finally
            Free;
          end;
        except on E: Exception do
          WriteLn('LOG:' + log_fn + ' ' + E.Message);
        end;
      end;
    end;
  end;
end;

initialization

  log_sem := TSemaphore.Create(1);
  find_log_file();

finalization

  if assigned( log_fs ) then
    log_fs.free;

  FreeAndNil( log_sem );

end.

