program filelisttohtml;
{$CONSOLEAPP}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes
  , DateUtils
  , SysUtils
  , strutils
  { you can add units after this };

// Function to sort strings in descending order
function CompareStringsDesc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := -AnsiCompareText(List[Index1], List[Index2]);
end;

// Function to get the date and time of the last file modification
function GetFileLastWriteTime(const FilePath: string): string;
var
  iFileAge: Integer;
  FileDate: TDateTime;
begin
  iFileAge := FileAge(FilePath);
  if iFileAge <> -1 then
  begin
    FileDate := FileDateToDateTime(iFileAge);
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', FileDate);
  end
  else
    Result := 'Unknown';
end;

var
  fileCount: Integer = 0;
  pageBegin: Integer = 0;
  pageLength: Integer = 0;

procedure add_toList(var FileList: TStringList; const aFile: String);
begin
  fileCount := fileCount +1;
  if
    (
          ((pageBegin = 0)or(pageLength=0))
          or
          ((fileCount >= pageBegin)and(fileCount < pageBegin + pageLength))
    ) then
      FileList.Add(aFile);
end;

procedure Search_toList(const DirectoryPath,Filter: string; IncludeSubdirs: Boolean; var FileList: TStringList);
var
  SearchRec: TSearchRec;

begin
  if FindFirst(IncludeTrailingPathDelimiter(DirectoryPath) + Filter, faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then // Skip directories
        //FileList.Add(IncludeTrailingPathDelimiter(DirectoryPath) + SearchRec.Name)
      add_toList(FileList, IncludeTrailingPathDelimiter(DirectoryPath) + SearchRec.Name)
      ;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
  if fileCount > pageBegin + pageLength then Exit;

  if FindFirst(IncludeTrailingPathDelimiter(DirectoryPath) + Filter, faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then // Skip directories
        //FileList.Add(IncludeTrailingPathDelimiter(DirectoryPath) + SearchRec.Name)
      else
        if IncludeSubdirs and (not((SearchRec.Name = '.')or(SearchRec.Name='..'))) then
          Search_toList(IncludeTrailingPathDelimiter(DirectoryPath) + SearchRec.Name, Filter, IncludeSubdirs, FileList);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

end;

// Main procedure
procedure GenerateHTML( DirectoryPath: string; SortOrder: string; const Filter: string; IncludeSubdirs: Boolean);
var
  FileList: TStringList;
  FilePath: string;
  FileName: string;
  LastWriteTime, s: string;
  HTML: TStringList;
begin
  //if DirectoryPath[length(DirectoryPath)] <> PathDelim then
  //    DirectoryPath := DirectoryPath + PathDelim;
  // Create a list to store the files
  FileList := TStringList.Create;
  try
    // Search for files by the filter

    Search_toList(DirectoryPath, Filter, IncludeSubdirs, FileList);

    // Sort the list of files
    if SortOrder = 'asc' then
      FileList.Sort // Ascending
    else if SortOrder = 'desc' then
      FileList.CustomSort(@CompareStringsDesc); // Descending

    // Create the HTML document
    HTML := TStringList.Create;
    try
      HTML.Add('<html>');
      HTML.Add('<body>');
      s := Format('/shell?cmd=filelisttohtml path=%s&sort=%s&filter=%s&subdir=%s&begin=%d&count=%d'
            , [DirectoryPath, SortOrder, Filter, ifthen(IncludeSubdirs, 'y', '-')
            , pageBegin - pageLength
            , pageLength]);
      HTML.Add(Format('<div><a href="%s"><<<--</a></div>', [s]));
      HTML.Add(Format('<div><h3>%d--%d</h3></div>', [pageBegin, pageLength]));

      // Add an <img> tag for every file
      for FilePath in FileList do
      begin
        FileName := ExtractFileName(FilePath);
        LastWriteTime := GetFileLastWriteTime(FilePath);
        s := format('Name: %s, Last Modified: %s', [FileName, LastWriteTime]);
        HTML.Add(Format('<div><img src="%s" alt="%s" title="%s"></div>'

                                   ,[FilePath, s, s]));
      end;

      s := Format('/shell?cmd=filelisttohtml path=%s&sort=%s&filter=%s&subdir=%s&begin=%d&count=%d'
            , [DirectoryPath, SortOrder, Filter, ifthen(IncludeSubdirs, 'y', '-')
            , pageBegin + pageLength
            , pageLength]);
      HTML.Add(Format('<div><a href="%s">-->>></a></div>', [s]));

      HTML.Add('</body>');
      HTML.Add('</html>');

      // Save the HTML document to a file
      HTML.SaveToFile('output.html');
      //WriteLn('HTML document created successfully: output.html');
      //writeln( HTML.Text);
    finally
      HTML.Free;
    end;
  finally
    FileList.Free;
  end;
end;



// Function to parse the command line arguments
//procedure ParseArguments(var DirectoryPath, SortOrder, Filter: string; var IncludeSubdirs: Boolean);
//var
//  i: Integer;
//  Arg: string;
//begin
//  DirectoryPath := '';
//  SortOrder := 'asc'; // Sorting ascending by default
//  Filter := '*.*';    // All files by default
//  IncludeSubdirs := False;
//
//  i := 1;
//  while i <= ParamCount do
//  begin
//    Arg := ParamStr(i);
//    if Arg = '--sort' then
//    begin
//      Inc(i);
//      if i <= ParamCount then
//        SortOrder := ParamStr(i);
//    end
//    else if Arg = '--filter' then
//    begin
//      Inc(i);
//      if i <= ParamCount then
//        Filter := ParamStr(i);
//    end
//    else if Arg = '--recursive' then
//    begin
//      IncludeSubdirs := True;
//    end
//    else if DirectoryPath = '' then
//    begin
//      DirectoryPath := Arg;
//    end;
//    Inc(i);
//  end;
//
//  // Check for the mandatory parameter (path to the directory)
//  if DirectoryPath = '' then
//  begin
//    WriteLn('Error: No path to the directory specified.');
//    WriteLn('Usage: FileListToHTML <path_to_directory> [--sort asc|desc] [--filter <mask>] [--recursive]');
//    //Halt(1);
//  end;
//end;

function getArgName(const aArgs: String): String;
var i : Integer;
begin
  Result := '';
  i := pos('=', aArgs);
  if i > 0 then
    Result := trim(copy(aArgs,1, i-1));
end;

function getArgVal(const aArgs: String): String;
var i : Integer;
begin
  Result := '';
  i := pos('=', aArgs);
  if i > 0 then
    Result := trim(copy(aArgs,i+1, length(aArgs)));
  i := length(Result);
  if i > 1 then
    if (Result[1] = '"')and(Result[i] = '"') then
      Result := copy(Result, 2, i-2);
end;

procedure ParseArguments(var aDirectoryPath, aSortOrder, aFilter: string; var aIncludeSubdirs: Boolean);
var
  i,j: Integer;
  Arg: string;
  sa_arg:TStringArray;
  value: string;
begin
  //the arguments are written as one line with the & separator.
  //
  aDirectoryPath:= '';
  if ParamCount < 1 then
   Exit;

  sa_arg := ParamStr(1).Split(['&']);
  for i := 0 to length(sa_arg)-1 do
  begin
    arg := getArgName(sa_arg[i]);
    value := getArgVal(sa_arg[i]);

    if arg = 'path' then aDirectoryPath:= value;
    if arg = 'sort' then aSortOrder:= value;
    if arg = 'filter' then aFilter:= value;
    if arg = 'subdir' then aIncludeSubdirs:= value='y';
    if arg = 'begin' then TryStrToInt(value, pageBegin);
    if arg = 'count' then TryStrToInt(value, pageLength);
  end;

end;

//path="Z:\BACKUP\Clipart"&sort=desc&filter="*.*"
//path="Z:\BACKUP\Clipart"&sort=desc&filter="*.*"&subdir=y

// Main block of the program
var
  DirectoryPath: string;
  SortOrder: string;
  Filter: string;
  IncludeSubdirs: Boolean;
begin
  // Parse the command line arguments
  ParseArguments(DirectoryPath, SortOrder, Filter, IncludeSubdirs);

  // Check that the directory exists
  if not DirectoryExists(DirectoryPath) then
  begin
    WriteLn('Error: Th catalog "', DirectoryPath, '" does not exist.');
    Exit;
  end;

  // Generate the HTML document
  GenerateHTML(DirectoryPath, SortOrder, Filter, IncludeSubdirs);
end.


