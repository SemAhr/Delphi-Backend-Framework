unit Logger;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Logger.Port,
  Logger.Options,
  Options.Port;

type
  TLogger = class(TInterfacedObject, ILogger)
  private
    FCriticalSection: TCriticalSection;
    FOptions: TLoggerOptions;

    function ColorForLevel(const ALevel: TLogLevel): string;
    procedure WriteToConsole(const ALevel: TLogLevel; const ADate: string; const AMessage: string);
    procedure WriteToFile(const AMessage: string);
  public
    constructor Create(const AOptions: IOptions<TLoggerOptions>);
    destructor Destroy; override;

    procedure Log(const Level: TLogLevel; const Message: string);

    procedure Debug(const Message: string);
    procedure Info(const Message: string);
    procedure Warning(const Message: string);
    procedure Error(const Message: string);
  end;

implementation

uses
  AppExceptions,
  Path.Helpers;

constructor TLogger.Create(const AOptions: IOptions<TLoggerOptions>);
begin
  inherited Create;

  if AOptions = nil then
    raise EMissingDependencyException.Create('Logger options are required.');

  FOptions := AOptions.Value;

  if FOptions.LogLevel.IsEmpty then
    raise EInvalidDependencyException.Create('Log level option is required.');

  if FOptions.FilePath.IsEmpty then
    raise EInvalidDependencyException.Create('Log file path option is required.');

  if not TPathHelpers.TryValidatePath(
    FOptions.FilePath,
    TPathKind.FilePath,
    True,
    False,
    True
  ) then
    raise EInvalidDependencyException.Create('Log file is not valid.');

  if not TPathHelpers.CanBeOpen(FOptions.FilePath) then
    raise EInvalidDependencyException.Create('Log file cannot be opened.');

  FCriticalSection := TCriticalSection.Create;
end;

destructor TLogger.Destroy;
begin
  FCriticalSection.Free;
  inherited;
end;

function TLogger.ColorForLevel(const ALevel: TLogLevel): string;
begin
  case ALevel of
    TLogLevel.llDebug:
      Result := #27'[36m';

    TLogLevel.llInfo:
      Result := #27'[32m';

    TLogLevel.llWarning:
      Result := #27'[33m';

    TLogLevel.llError:
      Result := #27'[31m';
  else
    Result := '';
  end;
end;

procedure TLogger.WriteToConsole(const ALevel: TLogLevel; const ADate: string; const AMessage: string);
const
  ResetColor = #27'[0m';
begin
  Writeln(ColorForLevel(ALevel) + ADate + ResetColor + AMessage);
end;

procedure TLogger.WriteToFile(const AMessage: string);
var
  LogFile: TextFile;
  FileOpened: Boolean;
begin
  FileOpened := False;

  try
    AssignFile(LogFile, FOptions.FilePath);

    if FileExists(FOptions.FilePath) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    FileOpened := True;

    Writeln(LogFile, AMessage);
  except
    on Error: Exception do
      raise EInfrastructureUnavailableException.CreateFmt(
        'Cannot write to log file "%s": %s',
        [FOptions.FilePath, Error.Message]
      );
  end;

  if FileOpened then
    CloseFile(LogFile);
end;

procedure TLogger.Log(const Level: TLogLevel; const Message: string);
var
  FormattedDate: string;
begin
  if FCriticalSection = nil then
    raise EMissingDependencyException.Create('Logger has not been initialized.');

  if Ord(Level) < Ord(FOptions.LogLevelEnum) then
    Exit;

  FormattedDate := Format(
    '[%s] [%s] ',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now), TLoggerOptions.ToString(Level)]
  );

  FCriticalSection.Enter;
  try
    WriteToConsole(Level, FormattedDate, Message);
    WriteToFile(Format('%s %s', [FormattedDate, Message]));
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TLogger.Debug(const Message: string);
begin
  Log(TLogLevel.llDebug, Message);
end;

procedure TLogger.Info(const Message: string);
begin
  Log(TLogLevel.llInfo, Message);
end;

procedure TLogger.Warning(const Message: string);
begin
  Log(TLogLevel.llWarning, Message);
end;

procedure TLogger.Error(const Message: string);
begin
  Log(TLogLevel.llError, Message);
end;

end.
