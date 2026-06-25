unit Logger.Port;

interface

uses
  Logger.Options;

type
  ILogger = interface
    ['{22F4D393-B40A-4574-A428-75579F4C4386}']

    procedure Log(const Level: TLogLevel; const Message: string);

    procedure Debug(const Message: string);
    procedure Info(const Message: string);
    procedure Warning(const Message: string);
    procedure Error(const Message: string);
  end;

implementation

end.
