unit u_srvhttp2_route;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,  httpdefs, httproute;

type
  T_RouteCallBackPtr = procedure(aValue:String);

procedure route1(aReq: TRequest; aResp: TResponse);
procedure route2(aReq: TRequest; aResp: TResponse);

var
  RouteCallBack : T_RouteCallBackPtr = nil;

implementation

uses
    {u_conf
  ,} strutils
  , u_ownlogger
  ;

const
  C_HTML_STYLE = '<style type="text/css">'
    + 'label {color:#0077FF;}'
    + 'input[type=text] {color:#885588;border:none;}'
    + 'input[type=password] {color:#885588;border:none;}'
    + 'input[type=submit] {border-radius: 5px; width: -webkit-fill-available;margin-top:10px;}'
    + 'tr {background-color: azure; border-radius: 5px;}'

    + 'body, html { '
    + ' height: 100%;'
    + '  margin: 0;'
    + ' font-family: Arial;'
    + '}'


    + '.tablink {'
    + '  background-color: #555;'
    + '  color: white;'
    + '  float: left;'
    + '  border: none;'
    + '  outline: none;'
    + '  cursor: pointer;'
    + '  padding: 14px 16px;'
    + '  font-size: 12px;'
    + '  width: 12%;'
    + '}'

    + '.tablink:hover {'
    + '  background-color: #777;'
    + '}'


    + '.tabcontent {'
    + '  color: white;'
    + '  display: none;'
    + '  padding: 10px 20px;'
    + '  height: 100%;'
    + '}'

    + '#Home {background-color: red;}'
    + '#News {background-color: green;}'
    + '#Contact {background-color: blue;}'
    + '#About {background-color: orange;}'

    + '</style>';
  C_HTML_JAVA = '<script>'#13#10
    + 'function openPage(pageName, elmnt, color) {'#13#10
    +'  var i, tabcontent, tablinks;'
    +'  tabcontent = document.getElementsByClassName("tabcontent");'#13#10
    +'  for (i = 0; i < tabcontent.length; i++) {'#13#10
    +'    tabcontent[i].style.display = "none";'#13#10
    +'  }'#13#10
    +'  tablinks = document.getElementsByClassName("tablink");'#13#10
    +'  for (i = 0; i < tablinks.length; i++) {'#13#10
    +'    tablinks[i].style.backgroundColor = "";'#13#10
    +'  }'
    +'  document.getElementById(pageName).style.display = "block";'#13#10
    +'  elmnt.style.backgroundColor = color;'#13#10
    +'}'#13#10
    +'document.getElementById("ts0").click();'#13#10
    +'</script>';


  C_HTML_TLBTN = ' <button class="tablink" onclick="openPage(''%s'', this, ''green'')" id="ts%d">%s</button>';
  C_HTML_TLDIV =
       '<div id="%s" class="tabcontent">'
      + '<h3>%s</h3>'
      + '<p>%s</p>'
      + '</div>';



function getValueByName(const aReq: TRequest; const aName,aDefValue: String): String;
var
  i : Integer;
  //cfg : TConfig;
begin
  //cfg := TConfig.ConfigInstance;
  Result := aDefValue;
  i := aReq.ContentFields.IndexOfName(aName);
  if i >= 0 then Exit( aReq.ContentFields.ValueFromIndex[i]);
  i := aReq.QueryFields.IndexOfName(aName);
  if i >= 0 then Exit( aReq.ContentFields.ValueFromIndex[i]);
end;

const
  C_HTML_TPL_LABELEDIT =
      '<tr><td><label for="%s">%s:</Label></td><td>'
    + '<input type=%s name="%s" value="%s" /> '
    + '</td></tr>';


procedure route1(aReq: TRequest; aResp: TResponse);
var
  i,j : integer;
  s,s1,s2,s0,defval, pn : String;
  pwd: Boolean;
  //cfg : TConfig;
begin

  //cfg := TConfig.ConfigInstance;

  for i := 0 to aReq.QueryFields.Count -1 do
    writeln(aReq.QueryFields[i]);
  Writeln('contentfields:');
  for i := 0 to aReq.ContentFields.Count -1 do
    //writeln(aReq.ContentFields[i])
    ;

  /////////////////////////////////////////////////
  for i := 0 to aReq.ContentFields.Count -1 do
  begin
    s  := aReq.ContentFields.Names[i];
    s1 := aReq.ContentFields.ValueFromIndex[i];
    //if s = cfg.C_SEC_APP + cfg.C_PAR_ClientID then s1 := cfg.encode_str(s1);
    //if s = cfg.C_SEC_APP + cfg.C_PAR_ClientPwd then s1 := cfg.encode_str(s1);
    //if s = cfg.C_SEC_DB + cfg.C_PAR_DBPwd then s1 := cfg.encode_str(s1);
    //cfg.asString[ s ] := s1;
  end;
  //if cfg.isCfgChanged then
  //   cfg.saveConfig;

  /////////////////////////////////////////////////

  S := ''; s0 := '';
  ////for i := 0 to high(TConfig.C_ARR_PARS) do
  ////  s := S + Format(C_HTML_TPL_LABELEDITC_HTML_TPL_LABELEDIT
  ////       , [
  ////              TConfig.C_ARR_PARS[i]
  ////            , TConfig.C_ARR_TXTS[i]
  ////            , ifthen(i = 2, 'password', 'text')
  ////            , TConfig.C_ARR_PARS[i]
  ////            , getValueByName(aReq, TConfig.C_ARR_PARS[i], TConfig.C_ARR_DEFS[i])
  ////         ]);
  //for i := low(TConfig.C_FULL_CFG) to high(TConfig.C_FULL_CFG) do
  //begin
  //  //s1 := TConfig.C_FULL_CFG[i].SEC_NAME;
  //  s0 := s0 + Format(C_HTML_TLBTN
  //                        , [s1, i, s1]
  //                  );
  //end;
  //for i := low(TConfig.C_FULL_CFG) to high(TConfig.C_FULL_CFG) do
  begin
    //s1 := TConfig.C_FULL_CFG[i].SEC_NAME;
    s2 := '<table>';
    //for j := low(TConfig.C_FULL_CFG[i].PARAMS) to high(TConfig.C_FULL_CFG[i].PARAMS) do
    //begin
    //  pwd := ((i = 0) and (j = 2))
    //         //or((i = 0)and(j = 1))
    //         or((i = 1)and(j = 4));
    //
    //  pn := cfg.C_FULL_CFG[i].SEC_NAME + cfg.C_FULL_CFG[i].PARAMS[j];
    //
    //  defval := cfg.C_FULL_CFG[i].DEFVAL[j];
    //  if cfg.paramExist( pn ) then
    //    defval := cfg.asString[ pn ];
    //  s2 := s2 + Format(C_HTML_TPL_LABELEDIT
    //       , [
    //              pn//cfg.C_FULL_CFG[i].PARAMS[j]
    //            , cfg.C_FULL_CFG[i].TXT[j]
    //            , ifthen( pwd, 'password', 'text')
    //            , pn//cfg.C_FULL_CFG[i].PARAMS[j]
    //            , getValueByName(aReq, pn, defval)
    //         ]);
    //end;
    s2 := s2 + '<tr><td><input type=submit value="save" /></td></tr></table>';


    s := s + Format(C_HTML_TLDIV
                          , [s1, s1, s2]
                    );
  end;

  aResp.Content:='<html>'+ C_HTML_STYLE + C_HTML_JAVA + '<body><h3>Set the configuration</h3>'
  + s0
  + '<div><form method="POST">'
  + s
  //+ '<tr><td><input type=submit value="save" /></td></tr> </table>'
  + '</form></div>'
  + '</body></html>';
end;

procedure route2(aReq: TRequest; aResp: TResponse);
var
  xmlstr: string;

begin
  setLength(xmlstr, 0);
  if aReq.ContentFields.Count > 0 then
    begin
      xmlstr := getValueByName( aReq, 'xmltext', '');
      DebugLn('route 2: xmlsrtr=' + xmlstr);
    end;

  if Assigned(RouteCallBack) then
    try
       RouteCallBack( xmlstr );
    except on E: Exception do
      DebugLn('route 2:E:' + e.Message);
    end;

  aResp.Content:='<html><body><h1>Route 2</h1>'

  +'<form method="POST"><p>XML</p>'
  +'<p><textarea name="xmltext" cols="30" rows="30">'+ xmlstr+ '</textarea></p>'
  +'<input type=submit value="Send" />'
  +'</form></body></html>';


end;

end.

