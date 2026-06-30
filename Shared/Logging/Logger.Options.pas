unit Logger.Options;

interface

uses
  Logger.Port;

type
  TLoggerOptions = record
  private
    function GetLogLevel: TLogLevel;
  public
    LogLevel: string;
    FilePath: string;

    property LogLevelEnum: TLogLevel read GetLogLevel;

    class function ToString(const ALogLevel: TLogLevel): string; static;
  end;

implementation

uses
  System.SysUtils,
  AppExceptions;

function TLoggerOptions.GetLogLevel: TLogLevel;
begin
  var NormalizedLevel := LogLevel.Trim.ToUpper;

  if NormalizedLevel = 'DEBUG' then
    Exit(TLogLevel.llDebug);

  if NormalizedLevel = 'INFO' then
    Exit(TLogLevel.llInfo);

  if NormalizedLevel = 'WARNING' then
    Exit(TLogLevel.llWarning);

  if NormalizedLevel = 'ERROR' then
    Exit(TLogLevel.llError);

  raise EInvalidDependencyException.Create('Invalid log level value.');
end;

class function TLoggerOptions.ToString(const ALogLevel: TLogLevel): string;
begin
  case ALogLevel of
    TLogLevel.llDebug:
      Result := 'DEBUG';

    TLogLevel.llInfo:
      Result := 'INFO';

    TLogLevel.llWarning:
      Result := 'WARNING';

    TLogLevel.llError:
      Result := 'ERROR';
  else
    Result := 'INFO';
  end;
end;

end.
