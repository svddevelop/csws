unit u_versionsinfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

procedure ReadVersionInfoParams(aInstance: QWord;AParamsList: TStrings);

implementation

uses
  versiontypes, versionresource, LCLType;

//const
//  RT_VERSION = 1 ;

procedure ReadVersionInfoParams(aInstance: QWord;AParamsList: TStrings);
var
  VersionInfo: TVersionResource;
  Stream: TResourceStream;
  i,j: Integer;
  Key, Value: string;
begin

  VersionInfo := TVersionResource.Create;
  try

    Stream := TResourceStream.CreateFromID(aInstance, 1, PChar(RT_VERSION));
    try
      VersionInfo.SetCustomRawDataStream(Stream);

      for i := 0 to VersionInfo.StringFileInfo.Count - 1 do
      begin
        for j := 0 to VersionInfo.StringFileInfo.Items[i].Count -1 do
        begin
          Key := VersionInfo.StringFileInfo.Items[i].Keys[j];
          Value := VersionInfo.StringFileInfo.Items[i].ValuesByIndex[j];

          if Value <> '' then
          begin
            AParamsList.Add(Key + '=' + Value);
          end;

        end;
      end;
    finally
      Stream.Free;
    end;
  finally
    VersionInfo.Free;
  end;
end;

end.

