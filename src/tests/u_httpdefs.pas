unit u_httpdefs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, HTTPDefs, fphttpserver ;

type

  { T_Response }

  T_Response = class(TFPHTTPConnectionResponse)
  private
    FConnection: TFPHTTPConnection;
  protected
    Procedure DoSendHeaders(Headers : TStrings); override;
    Procedure DoSendContent; override;
    Property Connection : TFPHTTPConnection Read FConnection;

  end;

implementation

{ T_Response }

procedure T_Response.DoSendHeaders(Headers: TStrings);
begin
  //////////inherited DoSendHeaders(Headers);
end;

procedure T_Response.DoSendContent;
begin
  /////inherited DoSendContent;
end;

end.

