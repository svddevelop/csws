unit u_safememorystream;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, SyncObjs;

type

  { TSafeMemoryStream }

  TSafeMemoryStream = class
  private
    FStream: TMemoryStream;
    FCriticalSection: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Push(const Data: TBytes; const aDataSize: Integer);
    function Pop(Count: Integer): TBytes;
    function PopRawByteString(Count: Integer): RawByteString;
    procedure PushRawByteString(const Data: RawByteString);
  end;

var
  SafeMemoryStream : TSafeMemoryStream = nil;

implementation

{ TSafeMemoryStream }

constructor TSafeMemoryStream.Create;
begin
  inherited Create;
  FStream := TMemoryStream.Create;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TSafeMemoryStream.Destroy;
begin
  FCriticalSection.Free;
  FStream.Free;
  inherited Destroy;
end;

procedure TSafeMemoryStream.Push(const Data: TBytes; const aDataSize: Integer);
begin
  FCriticalSection.Enter;
  try
    FStream.Position := FStream.Size;
    FStream.WriteBuffer(Data[0], aDataSize);
  finally
    FCriticalSection.Leave;
  end;
end;

function TSafeMemoryStream.Pop(Count: Integer): TBytes;
var
  RemainingData: TBytes;
begin
  FCriticalSection.Enter;
  try
    if FStream.Size = 0 then
      Exit(nil);


    if Count > FStream.Size then
      Count := FStream.Size;

    SetLength(Result, Count);
    FStream.Position := 0;
    FStream.ReadBuffer(Result[0], Count);


    if FStream.Size > Count then
    begin
      SetLength(RemainingData, FStream.Size - Count);
      FStream.ReadBuffer(RemainingData[0], Length(RemainingData));
      FStream.Clear;
      FStream.WriteBuffer(RemainingData[0], Length(RemainingData));
    end
    else
    begin
      FStream.Clear;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSafeMemoryStream.PushRawByteString(const Data: RawByteString);
begin
  FCriticalSection.Enter;
  try
    FStream.Position := FStream.Size;
    FStream.WriteBuffer(Pointer(Data)^, Length(Data));
  finally
    FCriticalSection.Leave;
  end;
end;

function TSafeMemoryStream.PopRawByteString(Count: Integer): RawByteString;
var
  RemainingData: RawByteString;
begin
  FCriticalSection.Enter;
  try
    if FStream.Size = 0 then
      Exit('');


    if Count > FStream.Size then
      Count := FStream.Size;


    SetLength(Result, Count);
    FStream.Position := 0;
    FStream.ReadBuffer(Pointer(Result)^, Count);

    // Copy the remaining data to the beginning of the stream
    if FStream.Size > Count then
    begin
      SetLength(RemainingData, FStream.Size - Count);
      FStream.ReadBuffer(Pointer(RemainingData)^, Length(RemainingData));
      FStream.Clear;
      FStream.WriteBuffer(Pointer(RemainingData)^, Length(RemainingData));
    end
    else
    begin
      FStream.Clear;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

end.

