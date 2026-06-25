unit Error.Dto;

interface

uses
  Dto.Attributes;

type
  TErrorDto = class
  private
    FError: string;
    FMessages: TArray<string>;
  public
    [JsonName('error')]
    property Error: string read FError write FError;

    [JsonName('messages')]
    property Messages: TArray<string> read FMessages write FMessages;
  end;

implementation

end.
