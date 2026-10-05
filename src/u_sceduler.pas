unit u_sceduler;

{ Task scheduler for csws.
  The scheduler is started with the command line switch --sceduler and runs
  together with the web server.

  Configuration file layout:

    [scedule]                -- section with the active schedules,
                                one entry per line as <name>=1,
                                a plain <name> is accepted too;
    [scedule.<name>]         -- section with the settings of one schedule:
        Command              -- the command (path) which must be executed;
        Period               -- how often the command must be executed,
                                human readable format:
                                  30s, 15m, 1h, 1h30m, 1d   (duration)
                                  daily, weekly              (keyword)
                                  daily at=03:00             (time of day)
        LastRun              -- date and time of the last run
                                (yyyy-mm-dd hh:nn:ss), empty = never run.

  The scheduler checks all active schedules once per second. If the period
  of the last run is exceeded the command is started in background and its
  output is printed to the console. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, SyncObjs;

const
  C_SEC_SCED       = 'scedule';
  C_SEC_SCED_PREF  = 'scedule.';
  C_PAR_COMMAND    = 'Command';
  C_PAR_PERIOD     = 'Period';
  C_PAR_LASTRUN    = 'LastRun';
  C_DEF_PERIOD     = '1h';

type
  TScedPeriodKind = (spkDuration, spkDaily, spkWeekly);

  { TScedTaskThread -- executes one schedule command in background
    and prints its output to the console }

  TScedTaskThread = class(TThread)
  private
    FTaskName: String;
    FCommand: String;
    FCompleted: Boolean;
    function getScedTag: String;
  protected
    procedure Execute; override;
  public
    constructor Create(const aTaskName, aCommand: String);
    property Completed: Boolean read FCompleted;
    property TaskName: String read FTaskName;
    property Command: String read FCommand;
  end;

  { TThdSceduler -- checks every second which schedules must be started }

  TThdSceduler = class(TThread)
  private
    FTasks: TFPList;       // running TScedTaskThread objects
    FInvalid: TStringList; // names of schedules with a broken Period value
    function  IsTaskRunning(const aName: String): Boolean;
    procedure StopFinishedTasks;
    procedure StartTask(const aName, aCommand: String);
    procedure CheckTasks;
    procedure WarnInvalidOnce(const aName, aPeriod: String);
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor  Destroy; override;
  end;

{ period parsing / next run calculation }
function ScedParsePeriod(const aPeriod: String; out aKind: TScedPeriodKind;
  out aDuration: TDateTime; out aHasAt: Boolean;
  out aAtHour, aAtMinute: Integer): Boolean;
function ScedCalcNextRun(const aPeriod: String; const aLastRun: TDateTime;
  out aNextRun: TDateTime): Boolean;

{ date/time helpers, the format is yyyy-mm-dd hh:nn:ss }
function ScedParseDateTime(const aText: String): TDateTime;
function ScedFormatDateTime(const aDateTime: TDateTime): String;

{ command line helpers }
function  ScedValidName(const aName: String): Boolean;
procedure ScedNew(const aName, aCommand, aPeriod: String);
procedure ScedDelete(const aName: String);
procedure ScedActivate(const aName: String);
procedure ScedDeactivate(const aName: String);
procedure ScedList;

{ console output protected against interleaving of several threads }
procedure ScedWriteLn(const aTag, aText: String);

implementation

uses
  inifiles
  , DateUtils
  , u_conf
  ;

var
  ScedConsoleLock: TCriticalSection;

procedure ScedWriteLn(const aTag, aText: String);
begin
  ScedConsoleLock.Enter;
  try
    if aTag <> '' then
      WriteLn('[', aTag, '] ', aText)
    else
      WriteLn(aText);
    Flush(Output);
  finally
    ScedConsoleLock.Leave;
  end;
end;

function ScedSectionOf(const aName: String): String;
begin
  Result := C_SEC_SCED_PREF + aName;
end;

{ ---------------------------------------------------------------------------- }
{ the list of the active schedules in [scedule]                                }
{ ---------------------------------------------------------------------------- }

{ Read the names of the active schedules.
  They are stored as "name=1", but a hand written configuration may also
  contain a plain "name" line or the "=name" line which the ini class writes
  for a line without '='; both are read as the plain name.
  aCanonical is False when the section does not hold "name=1" entries only,
  in that case the section must be rewritten with ScedWriteActive. }
procedure ScedReadActive(aIni: TIniFile; aList: TStringList;
  out aCanonical: Boolean);
var
  raw: TStringList;
  i, p: Integer;
  s, nm: String;
begin
  aCanonical := True;
  aList.Clear;
  raw := TStringList.Create;
  try
    aIni.ReadSectionRaw(C_SEC_SCED, raw);
    for i := 0 to raw.Count - 1 do
    begin
      s := Trim(raw[i]);
      if s = '' then Continue;
      if s[1] in [';', '#'] then Continue; // a comment inside the section
      p := Pos('=', s);
      if p > 1 then
        nm := Trim(Copy(s, 1, p - 1))       // name=1
      else
      begin
        if p = 1 then
          nm := Trim(Copy(s, 2, MaxInt))    // =name
        else
          nm := s;                          // plain name
        aCanonical := False;
      end;
      if nm = '' then Continue;
      if aList.IndexOf(nm) < 0 then
        aList.Add(nm);
    end;
  finally
    raw.Free;
  end;
end;

{ Rebuild [scedule] from the list of names, one entry is written as "name=1".
  Comments inside the section are dropped, the section is meant to be filled
  by the command line options. }
procedure ScedWriteActive(aIni: TIniFile; aList: TStrings);
var
  i: Integer;
begin
  aIni.EraseSection(C_SEC_SCED);
  for i := 0 to aList.Count - 1 do
    aIni.WriteString(C_SEC_SCED, aList[i], '1');
end;

{ ---------------------------------------------------------------------------- }
{ date/time helpers                                                            }
{ ---------------------------------------------------------------------------- }

function ScedParseDateTime(const aText: String): TDateTime;
var
  t: String;
  y, mo, d, h, mi, se: Integer;
begin
  // format: yyyy-mm-dd hh:nn:ss
  Result := 0;
  t := Trim(aText);
  if Length(t) < 19 then Exit;
  if t[5] <> '-' then Exit;
  if t[8] <> '-' then Exit;
  if (t[11] <> ' ') and (t[11] <> 'T') then Exit;
  if t[14] <> ':' then Exit;
  if t[17] <> ':' then Exit;

  if not TryStrToInt(Copy(t, 1, 4), y)   then Exit;
  if not TryStrToInt(Copy(t, 6, 2), mo)  then Exit;
  if not TryStrToInt(Copy(t, 9, 2), d)   then Exit;
  if not TryStrToInt(Copy(t, 12, 2), h)  then Exit;
  if not TryStrToInt(Copy(t, 15, 2), mi) then Exit;
  if not TryStrToInt(Copy(t, 18, 2), se) then Exit;

  if not TryEncodeDate(y, mo, d, Result) then
  begin
    Result := 0;
    Exit;
  end;
  try
    Result := Result + EncodeTime(h, mi, se, 0);
  except
    Result := 0;
  end;
end;

function ScedFormatDateTime(const aDateTime: TDateTime): String;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd" "hh":"nn":"ss', aDateTime);
end;

{ ---------------------------------------------------------------------------- }
{ period                                                                       }
{   duration : 30s, 15m, 1h, 1h30m, 1d                                        }
{   keyword  : daily, weekly                                                   }
{   time     : daily at=03:00, weekly at=22:30                                 }
{ ---------------------------------------------------------------------------- }

function ScedParsePeriod(const aPeriod: String; out aKind: TScedPeriodKind;
  out aDuration: TDateTime; out aHasAt: Boolean;
  out aAtHour, aAtMinute: Integer): Boolean;
var
  s, low, tail, numStr: String;
  i, l, n, p: Integer;
  hh, mm: Integer;
  unitCh: Char;

  function ParseAtTime(const aTime: String): Boolean;
  var
    parts: TStringArray;
    ph, pm: Integer;
  begin
    Result := False;
    ph := 0;
    pm := 0;
    parts := aTime.Split([':']);
    if Length(parts) <> 2 then Exit;
    if not TryStrToInt(Trim(parts[0]), ph) then Exit;
    if not TryStrToInt(Trim(parts[1]), pm) then Exit;
    if (ph < 0) or (ph > 23) then Exit;
    if (pm < 0) or (pm > 59) then Exit;
    hh := ph;
    mm := pm;
    Result := True;
  end;

begin
  Result := False;
  aKind := spkDuration;
  aDuration := 0;
  aHasAt := False;
  aAtHour := 0;
  aAtMinute := 0;
  hh := 0;
  mm := 0;

  s := Trim(aPeriod);
  if s = '' then Exit;
  low := LowerCase(s);

  // optional time of day: "... at=HH:MM"
  p := Pos('at=', low);
  if p > 0 then
  begin
    tail := Trim(Copy(s, p + 3, MaxInt));
    // the time of day ends at the next space or separator
    i := 1;
    while (i <= Length(tail)) and not (tail[i] in [' ', ',', ';']) do Inc(i);
    tail := Trim(Copy(tail, 1, i - 1));
    if not ParseAtTime(tail) then Exit;
    aHasAt := True;
    aAtHour := hh;
    aAtMinute := mm;
    s := Trim(Copy(s, 1, p - 1));
    low := LowerCase(s);
  end;

  if s = '' then Exit;

  if low = 'daily' then
  begin
    aKind := spkDaily;
    Exit(True);
  end;
  if low = 'weekly' then
  begin
    aKind := spkWeekly;
    Exit(True);
  end;

  // duration: one or more <number><unit> groups
  i := 1;
  l := Length(low);
  while i <= l do
  begin
    numStr := '';
    while (i <= l) and (low[i] in ['0'..'9']) do
    begin
      numStr := numStr + low[i];
      Inc(i);
    end;
    if numStr = '' then Exit;       // a unit without a number
    n := StrToIntDef(numStr, 0);
    if n <= 0 then Exit;
    if i > l then Exit;             // a number without a unit
    unitCh := low[i];
    Inc(i);
    case unitCh of
      's': aDuration := aDuration + n / SecsPerDay;
      'm': aDuration := aDuration + n / MinsPerDay;
      'h': aDuration := aDuration + n / HoursPerDay;
      'd': aDuration := aDuration + n;
    else
      Exit;                         // unknown unit
    end;
  end;
  Result := aDuration > 0;
end;

function ScedCalcNextRun(const aPeriod: String; const aLastRun: TDateTime;
  out aNextRun: TDateTime): Boolean;
var
  kind: TScedPeriodKind;
  dur: TDateTime;
  hasAt: Boolean;
  hh, mm: Integer;
  step, base: TDateTime;
  wHour, wMin, wSec, wMSec: Word;
begin
  aNextRun := 0;
  Result := ScedParsePeriod(aPeriod, kind, dur, hasAt, hh, mm);
  if not Result then Exit;

  if aLastRun <= 0 then
  begin
    // the schedule was never started before
    case kind of
      spkDuration:
        // no reference point in the past: start the task now
        aNextRun := 0;

      spkDaily, spkWeekly:
        if hasAt then
        begin
          // wait for the first occurrence of the time of day
          if kind = spkDaily then
            step := 1
          else
            step := 7;
          base := Int(Now) + EncodeTime(hh, mm, 0, 0);
          while base <= Now do
            base := base + step;
          aNextRun := base;
        end
        else
          // no time of day given: start the task now
          aNextRun := 0;
    end;
    Exit;
  end;

  case kind of
    spkDuration:
      aNextRun := aLastRun + dur;

    spkDaily, spkWeekly:
      begin
        if kind = spkDaily then
          step := 1
        else
          step := 7;
        if not hasAt then
        begin
          // keep the time of day of the last run
          DecodeTime(aLastRun, wHour, wMin, wSec, wMSec);
          hh := wHour;
          mm := wMin;
        end;
        base := Int(aLastRun) + EncodeTime(hh, mm, 0, 0);
        while base <= aLastRun do
          base := base + step;
        aNextRun := base;
      end;
  end;
  Result := True;
end;

{ ---------------------------------------------------------------------------- }
{ command line helpers                                                         }
{ ---------------------------------------------------------------------------- }

function ScedValidName(const aName: String): Boolean;
var
  s: String;
  i: Integer;
begin
  s := Trim(aName);
  Result := s <> '';
  if not Result then Exit;
  for i := 1 to Length(s) do
    if s[i] in ['[', ']', '=', ';'] then
      Exit(False);
end;

procedure ScedNew(const aName, aCommand, aPeriod: String);
var
  ini: TIniFile;
  name, period: String;
  k: TScedPeriodKind;
  dur: TDateTime;
  hasAt: Boolean;
  hh, mm: Integer;
begin
  name := Trim(aName);
  if not ScedValidName(name) then
  begin
    WriteLn('Option --scednew: the schedule name is empty or contains bad characters.');
    Exit;
  end;

  period := Trim(aPeriod);
  if period = '' then
    period := C_DEF_PERIOD;

  if not ScedParsePeriod(period, k, dur, hasAt, hh, mm) then
  begin
    WriteLn('Option --scednew: invalid period "', period, '".');
    WriteLn('Use 30s, 15m, 1h, 1h30m, 1d, daily, weekly, daily at=03:00.');
    Exit;
  end;

  ini := TIniFile.Create(TConfig.ini_filename);
  try
    if ini.SectionExists(ScedSectionOf(name)) then
    begin
      WriteLn('Schedule "', name, '" already exists.');
      Exit;
    end;

    ini.WriteString(ScedSectionOf(name), C_PAR_COMMAND, Trim(aCommand));
    ini.WriteString(ScedSectionOf(name), C_PAR_PERIOD, period);
    ini.WriteString(ScedSectionOf(name), C_PAR_LASTRUN, '');
    WriteLn('Schedule "', name, '" created with period "', period, '".');
    WriteLn('Set the ', C_PAR_COMMAND, ' value in the section [', ScedSectionOf(name), '].');
    WriteLn('Activate it with --scedon=', name);
  finally
    ini.Free;
  end;
end;

procedure ScedDelete(const aName: String);
var
  ini: TIniFile;
  lst: TStringList;
  name: String;
  canonical: Boolean;
  idx: Integer;
begin
  name := Trim(aName);
  if not ScedValidName(name) then
  begin
    WriteLn('Option --sceddel: the schedule name is empty or contains bad characters.');
    Exit;
  end;

  ini := TIniFile.Create(TConfig.ini_filename);
  lst := TStringList.Create;
  try
    if not ini.SectionExists(ScedSectionOf(name)) then
    begin
      WriteLn('Schedule "', name, '" not found.');
      Exit;
    end;
    ini.EraseSection(ScedSectionOf(name));
    // remove the name from the active list too
    ScedReadActive(ini, lst, canonical);
    idx := lst.IndexOf(name);
    if idx >= 0 then
    begin
      lst.Delete(idx);
      ScedWriteActive(ini, lst);
    end;
    WriteLn('Schedule "', name, '" deleted.');
  finally
    lst.Free;
    ini.Free;
  end;
end;

procedure ScedActivate(const aName: String);
var
  ini: TIniFile;
  lst: TStringList;
  name: String;
  canonical: Boolean;
begin
  name := Trim(aName);
  if not ScedValidName(name) then
  begin
    WriteLn('Option --scedon: the schedule name is empty or contains bad characters.');
    Exit;
  end;

  ini := TIniFile.Create(TConfig.ini_filename);
  lst := TStringList.Create;
  try
    if not ini.SectionExists(ScedSectionOf(name)) then
    begin
      WriteLn('Schedule "', name, '" not found. Create it with --scednew=', name);
      Exit;
    end;
    ScedReadActive(ini, lst, canonical);
    if lst.IndexOf(name) >= 0 then
    begin
      WriteLn('Schedule "', name, '" is already active.');
      Exit;
    end;
    lst.Add(name);
    ScedWriteActive(ini, lst);
    WriteLn('Schedule "', name, '" activated.');
  finally
    lst.Free;
    ini.Free;
  end;
end;

procedure ScedDeactivate(const aName: String);
var
  ini: TIniFile;
  lst: TStringList;
  name: String;
  canonical: Boolean;
  idx: Integer;
begin
  name := Trim(aName);
  if not ScedValidName(name) then
  begin
    WriteLn('Option --scedoff: the schedule name is empty or contains bad characters.');
    Exit;
  end;

  ini := TIniFile.Create(TConfig.ini_filename);
  lst := TStringList.Create;
  try
    ScedReadActive(ini, lst, canonical);
    idx := lst.IndexOf(name);
    if idx < 0 then
    begin
      WriteLn('Schedule "', name, '" is not active.');
      Exit;
    end;
    lst.Delete(idx);
    ScedWriteActive(ini, lst);
    WriteLn('Schedule "', name, '" deactivated.');
  finally
    lst.Free;
    ini.Free;
  end;
end;

procedure ScedList;
var
  ini: TIniFile;
  all, active: TStringList;
  i, j: Integer;
  sec, name, periodS, lastStr: String;
  lastRun, nextRun: TDateTime;
  ok: Boolean;
  nextStr: String;
  canonical: Boolean;
begin
  if not FileExists(TConfig.ini_filename) then
  begin
    WriteLn('Configuration file not found: ', TConfig.ini_filename);
    Exit;
  end;

  ini := TIniFile.Create(TConfig.ini_filename);
  all := TStringList.Create;
  active := TStringList.Create;
  try
    ini.ReadSections(all);
    ScedReadActive(ini, active, canonical);

    WriteLn(Format('%-7s %-20s %-14s %-20s %s',
      ['Active', 'Name', 'Period', 'Last run', 'Next run']));
    WriteLn(StringOfChar('-', 84));

    j := 0;
    for i := 0 to all.Count - 1 do
    begin
      sec := all[i];
      if not SameText(Copy(sec, 1, Length(C_SEC_SCED_PREF)), C_SEC_SCED_PREF) then
        Continue;
      name := Trim(Copy(sec, Length(C_SEC_SCED_PREF) + 1, MaxInt));
      if name = '' then Continue;

      periodS := ini.ReadString(sec, C_PAR_PERIOD, C_DEF_PERIOD);
      lastStr := ini.ReadString(sec, C_PAR_LASTRUN, '');
      lastRun := ScedParseDateTime(lastStr);

      ok := ScedCalcNextRun(periodS, lastRun, nextRun);
      if not ok then
        nextStr := 'invalid period'
      else if (nextRun > 0) and (nextRun <= Now) then
        nextStr := 'due now'          // the planned time is already past
      else if nextRun <= 0 then
        nextStr := 'due now'
      else
        nextStr := ScedFormatDateTime(nextRun);

      if lastRun <= 0 then
        lastStr := '-'
      else
        lastStr := ScedFormatDateTime(lastRun);

      if active.IndexOf(name) >= 0 then
        WriteLn(Format('%-7s %-20s %-14s %-20s %s',
          ['yes', name, periodS, lastStr, nextStr]))
      else
        WriteLn(Format('%-7s %-20s %-14s %-20s %s',
          ['no', name, periodS, lastStr, nextStr]));      Inc(j);
    end;

    if j = 0 then
      WriteLn('No schedules defined.');
  finally
    active.Free;
    all.Free;
    ini.Free;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ TScedTaskThread                                                              }
{ ---------------------------------------------------------------------------- }

constructor TScedTaskThread.Create(const aTaskName, aCommand: String);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTaskName := aTaskName;
  FCommand := aCommand;
  FCompleted := False;
end;

function TScedTaskThread.getScedTag: String;
begin
  Result := 'scedule:' + FTaskName;
end;

procedure TScedTaskThread.Execute;
var
  p: TProcess;
  buf: array[1..2048] of Byte;
  n: LongInt;
  chunk, line: String;
  idx: Integer;
begin
  line := '';
  p := TProcess.Create(nil);
  try
    try
      p.Executable := '/bin/sh';
      {$IFDEF WINDOWS}
      p.Executable := 'cmd.exe';
      {$ENDIF}
      p.Parameters.Clear;
      {$IFDEF WINDOWS}
      p.Parameters.Add('/c');
      {$ENDIF}
      {$IFDEF LINUX}
      p.Parameters.Add('-c');
      {$ENDIF}
      p.Parameters.Add(FCommand);
      p.Options := [poUsePipes, poStderrToOutPut];
      p.ShowWindow := swoHIDE;
      p.Execute;
      ScedWriteLn(getScedTag, 'started: ' + FCommand);

      // read the output of the command and print it line by line
      repeat
        while p.Output.NumBytesAvailable > 0 do
        begin
          n := p.Output.Read(buf, SizeOf(buf));
          if n > 0 then
          begin
            SetLength(chunk, n);
            Move(buf[1], chunk[1], n);
            line := line + chunk;

            idx := Pos(#10, line);
            while idx > 0 do
            begin
              chunk := Copy(line, 1, idx - 1);
              if (chunk <> '') and (chunk[Length(chunk)] = #13) then
                SetLength(chunk, Length(chunk) - 1);
              if chunk <> '' then
                ScedWriteLn(getScedTag, chunk);
              Delete(line, 1, idx);
              idx := Pos(#10, line);
            end;
          end;
        end;

        if Terminated then
          p.Terminate(0);
        Sleep(50);
      until (not p.Running) and (p.Output.NumBytesAvailable = 0);

      if line <> '' then
        ScedWriteLn(getScedTag, line);

      if Terminated then
        ScedWriteLn(getScedTag, 'stopped')
      else
      begin
        p.WaitOnExit;
        ScedWriteLn(getScedTag, Format('finished with exit code %d', [p.ExitStatus]));
      end;
    except
      on E: Exception do
        ScedWriteLn(getScedTag, 'error: ' + E.Message);
    end;
  finally
    p.Free;
    FCompleted := True;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ TThdSceduler                                                                 }
{ ---------------------------------------------------------------------------- }

constructor TThdSceduler.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := False;
  FTasks := TFPList.Create;
  FInvalid := TStringList.Create;
  FInvalid.CaseSensitive := True;
end;

destructor TThdSceduler.Destroy;
var
  i: Integer;
  th: TScedTaskThread;
begin
  // stop all background tasks of the scheduler
  for i := FTasks.Count - 1 downto 0 do
  begin
    th := TScedTaskThread(FTasks[i]);
    th.Terminate;
    th.WaitFor;
    th.Free;
  end;
  FTasks.Free;
  FInvalid.Free;
  inherited Destroy;
end;

function TThdSceduler.IsTaskRunning(const aName: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FTasks.Count - 1 do
    if SameText(TScedTaskThread(FTasks[i]).TaskName, aName) then
      Exit(True);
end;

procedure TThdSceduler.StopFinishedTasks;
var
  i: Integer;
  th: TScedTaskThread;
begin
  for i := FTasks.Count - 1 downto 0 do
  begin
    th := TScedTaskThread(FTasks[i]);
    if th.Completed then
    begin
      th.WaitFor;
      th.Free;
      FTasks.Delete(i);
    end;
  end;
end;

procedure TThdSceduler.StartTask(const aName, aCommand: String);
var
  th: TScedTaskThread;
begin
  th := TScedTaskThread.Create(aName, aCommand);
  FTasks.Add(th);
  th.Start;
end;

procedure TThdSceduler.WarnInvalidOnce(const aName, aPeriod: String);
begin
  if FInvalid.IndexOf(aName) >= 0 then Exit;
  FInvalid.Add(aName);
  ScedWriteLn('sceduler', 'schedule "' + aName + '": invalid period "' +
    aPeriod + '", skipped.');
end;

procedure TThdSceduler.CheckTasks;
var
  ini: TIniFile;
  active: TStringList;
  i: Integer;
  name, cmd, periodS, lastStr: String;
  lastRun, nextRun: TDateTime;
  sec: String;
  canonical: Boolean;
begin
  StopFinishedTasks;

  if not FileExists(TConfig.ini_filename) then Exit;

  ini := TIniFile.Create(TConfig.ini_filename);
  active := TStringList.Create;
  try
    // [scedule] holds the names of the active schedules
    ScedReadActive(ini, active, canonical);
    // bring a hand written list to the name=1 form, so that the ini class
    // does not turn a plain name into "=name" on the next save
    if not canonical then
      ScedWriteActive(ini, active);

    for i := 0 to active.Count - 1 do
    begin
      name := Trim(active[i]);
      if not ScedValidName(name) then Continue;
      if IsTaskRunning(name) then Continue;

      sec := ScedSectionOf(name);
      cmd := Trim(ini.ReadString(sec, C_PAR_COMMAND, ''));
      if cmd = '' then Continue; // nothing to do until Command is filled in

      periodS := Trim(ini.ReadString(sec, C_PAR_PERIOD, C_DEF_PERIOD));
      lastStr := ini.ReadString(sec, C_PAR_LASTRUN, '');
      lastRun := ScedParseDateTime(lastStr);

      if not ScedCalcNextRun(periodS, lastRun, nextRun) then
      begin
        WarnInvalidOnce(name, periodS);
        Continue;
      end;
      // drop the name from the warning list when the period is correct again
      if FInvalid.IndexOf(name) >= 0 then
        FInvalid.Delete(FInvalid.IndexOf(name));

      // 0 = never run before, so the task is due now
      if (nextRun > 0) and (nextRun > Now) then Continue;

      // remember the run before the command is started
      ini.WriteString(sec, C_PAR_LASTRUN, ScedFormatDateTime(Now));
      StartTask(name, cmd);
    end;
  finally
    active.Free;
    ini.Free;
  end;
end;

procedure TThdSceduler.Execute;
begin
  ScedWriteLn('sceduler', 'scheduler started, check interval: 1s');
  while not Terminated do
  begin
    try
      CheckTasks;
    except
      on E: Exception do
        ScedWriteLn('sceduler', 'check error: ' + E.Message);
    end;
    Sleep(1000);
  end;
  ScedWriteLn('sceduler', 'scheduler stopped');
end;

initialization
  ScedConsoleLock := TCriticalSection.Create;

finalization
  ScedConsoleLock.Free;

end.
