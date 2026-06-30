# Logging

The framework includes a default logger implementation.

Units:

```text
Shared/Logging/Logger.Port.pas
Shared/Logging/Logger.Options.pas
Shared/Logging/Logger.pas
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

```pascal
TLoggerOptions = record
  LogLevel: string;
  FilePath: string;
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

## Default registration

`TAppContainer` registers logger options by default:

```pascal
AddOptions<TLoggerOptions>('Logger');
```

If `TLogger` is registered as a dependency, it can receive options through constructor injection:

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

## Example registration

```pascal
Container.AddSingleton<ILogger, TLogger>;
```
