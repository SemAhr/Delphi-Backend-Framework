unit Logger.Options;

interface

uses
  Logger.Port,
  Options.Port;

type
  TLoggerOptions = class(TInterfacedObject, IOptionsSection)
  private
    FLogLevel: string;
    FFilePath: string;

    function GetSectionName: string;
    function GetLogLevel: TLogLevel;
  public
    property SectionName: string read GetSectionName;
    property LogLevel: string read FLogLevel write FLogLevel;
    property FilePath: string read FFilePath write FFilePath;
    property LogLevelEnum: TLogLevel read GetLogLevel;

    class function ToString(const ALogLevel: TLogLevel): string; static;
  end;

implementation

uses
  System.SysUtils,
  AppExceptions;

function TLoggerOptions.GetSectionName: string;
begin
  Result := 'Logger';
end;

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
