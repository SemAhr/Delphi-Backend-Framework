unit Http.Context;

interface

uses
  Http.Core;

type
  THttpContext = class
  private
    FRequest: TRequest;
  public
    constructor Create(const ARequest: TRequest);
    property Request: TRequest read FRequest;
  end;

implementation

constructor THttpContext.Create(const ARequest: TRequest);
begin
  inherited Create;
  FRequest := ARequest;
end;

end.
