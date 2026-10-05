program guiunittest;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Forms, GuiTestRunner, testcase1, u_CommandExecutor, u_conf,
  u_TestCommandExecutor, u_SimpleHTTPServer, u_strparams, u_mime_types,
  u_httpdefs, test_safememorystream;

{$R *.res}

procedure AllocateConsole;
begin
  if IsConsole then Exit; // If the console already exists, exit
  //AllocConsole; // Create the console window
  //IsConsole := True; // Tell that the console exists
  SysInitStdIO; // Redirect the standard input/output streams
end;

procedure FreeConsole;
begin
  if not IsConsole then Exit; // If the console does not exist, exit
  FreeConsole; // Close the console window
  IsConsole := False; // Tell that the console does not exist anymore
end;

begin
 // AllocateConsole;

  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;

 // FreeConsole;
end.

