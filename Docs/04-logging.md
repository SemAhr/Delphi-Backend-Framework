# Logging Example

The logger is not part of the framework core. It lives in the example application as an external-style dependency registered by the application bootstrap.

Units:

```text
Example/Infrastructure/Logging/Logger.Port.pas
Example/Infrastructure/Logging/Logger.Options.pas
Example/Infrastructure/Logging/Logger.pas
```

## Port

```pascal
ILogger = interface
  procedure Log(const Level: TLogLevel; const Message: string);
  procedure Debug(const Message: string);
  procedure Info(const Message: string);
  procedure Warning(const Message: string);
  procedure Error(const Message: string);
end;
```

## Log levels

`Logger.Port.pas` defines:

```pascal
TLogLevel = (llDebug, llInfo, llWarning, llError);
```

`Logger.Options.pas` maps string values from configuration to this enum.

Valid configured values:

- `Debug`
- `Info`
- `Warning`
- `Error`

Values are normalized using trim and uppercase comparison.

## Options

`TLoggerOptions` is an example options section:

```pascal
type
  TLoggerOptions = class(TOptionsSection)
  private
    FLogLevel: string;
    FFilePath: string;

    function GetSectionName: string; override;
  public
    property LogLevel: string read FLogLevel write FLogLevel;
    property FilePath: string read FFilePath write FFilePath;
  end;
```

The section name is defined by `GetSectionName`:

```pascal
function TLoggerOptions.GetSectionName: string;
begin
  Result := 'Logger';
end;
```

The root app config must contain:

```json
{
  "Logger": {
    "LogLevel": "Info",
    "FilePath": "./Logs/App.log"
  }
}
```

## Registration

The framework does not register the logger by default. The example application registers it in `Example/Bootstrap.pas`:

```pascal
App.AddOptions<TLoggerOptions>;
App.AddSingleton<ILogger, TLogger>;
```

`TLogger` receives its configuration through constructor injection:

```pascal
constructor TLogger.Create(const AOptions: IOptions<TLoggerOptions>);
```

## Behavior

`TLogger` writes to:

- console, with ANSI colors by level;
- file, using the configured `FilePath`.

It validates:

- `LogLevel` is present;
- `FilePath` is present;
- the log file path is valid;
- the log file can be opened.

Writes are synchronized using `TCriticalSection`.
