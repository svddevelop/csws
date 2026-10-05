unit test_safememorystream;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit;

procedure test__safememorystream_proc(aSender: TTestCase);

implementation

uses
  u_safememorystream
  ;

procedure test__safememorystream_proc(aSender: TTestCase);
var
  SafeStream: TSafeMemoryStream;
  Data, PoppedData: TBytes;
begin
  SafeStream := TSafeMemoryStream.Create;
  try
    // Push the data into the stream
    Data := TEncoding.UTF8.GetBytes('Hello, World!');
    SafeStream.Push(Data, length(Data));

    // Pop the data out of the stream
    PoppedData := SafeStream.Pop(5); // Pop 5 bytes
    WriteLn(TEncoding.UTF8.GetString(PoppedData)); // Output: Hello

    Data := TEncoding.UTF8.GetBytes('Hello, World!');
    SafeStream.Push(Data, length(Data));

    // Pop the remaining data
    PoppedData := SafeStream.Pop(10); // Pop all the remaining data
    WriteLn(TEncoding.UTF8.GetString(PoppedData)); // Output: , World!


    // Pop the remaining data
    PoppedData := SafeStream.Pop(100); // Pop all the remaining data
    WriteLn(TEncoding.UTF8.GetString(PoppedData)); // Output: , World!
  finally
    SafeStream.Free;
  end;
end;

end.

