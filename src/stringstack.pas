unit StringStack;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  TStringStack = class
  private
    FList: TStringList;       // List to store the strings
    FCriticalSection: TCriticalSection; // Critical section for the synchronization
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(const AValue: string); // Append a string to the end of the list
    function Pop: string; // Extract and remove the first string of the list
  end;

implementation

constructor TStringStack.Create;
begin
  inherited Create;
  FList := TStringList.Create; // Create the list
  FCriticalSection := TCriticalSection.Create; // Create the critical section
end;

destructor TStringStack.Destroy;
begin
  FCriticalSection.Free; // Free the critical section
  FList.Free; // Free the list
  inherited Destroy;
end;

procedure TStringStack.Push(const AValue: string);
begin
  FCriticalSection.Enter; // Enter the critical section
  try
    FList.Add(AValue); // Append a string to the end of the list
  finally
    FCriticalSection.Leave; // Leave the critical section
  end;
end;

function TStringStack.Pop: string;
begin
  FCriticalSection.Enter; // Enter the critical section
  try
    if FList.Count > 0 then
    begin
      Result := FList[0]; // Get the first string
      FList.Delete(0); // Remove the first string
    end
    else
      Result := ''; // Return an empty string when the list is empty
  finally
    FCriticalSection.Leave; // Leave the critical section
  end;
end;

end.
