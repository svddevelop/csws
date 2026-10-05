unit u_httpclient;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

procedure SendHttpRequest( AURL: string; AMethod: string = 'GET'; AParams: TStrings = nil);


implementation

uses
  fphttpclient;

procedure SendHttpRequest( AURL: string; AMethod: string = 'GET'; AParams: TStrings = nil);
var
  HttpClient: TFPHttpClient;
  Response: string;
  i: Integer;
begin
  HttpClient := TFPHttpClient.Create(nil);
  try
    HttpClient.AllowRedirect := True; // Allow redirects
    HttpClient.AddHeader('User-Agent', 'Mozilla/5.0 (compatible; fpweb)');
    HttpClient.AddHeader('Content-Type', 'application/x-www-form-urlencoded');


    if AMethod = 'GET' then
    begin

      if AParams <> nil then
      begin
        for i := 0 to AParams.Count - 1 do
        begin
          if i = 0 then
            AURL := AURL + '?' + AParams.Names[i] + '=' + AParams.ValueFromIndex[i]
          else
            AURL := AURL + '&' + AParams.Names[i] + '=' + AParams.ValueFromIndex[i];
        end;
      end;
      Response := HttpClient.Get(AURL);
    end
    else if AMethod = 'POST' then
    begin
      Response := HttpClient.FormPost(AURL, AParams);
    end
    else
    begin
      raise Exception.Create('Unsupported HTTP method: ' + AMethod);
    end;


    Writeln('Response:');
    Writeln(Response);
  finally
    HttpClient.Free;
  end;
end;

end.

