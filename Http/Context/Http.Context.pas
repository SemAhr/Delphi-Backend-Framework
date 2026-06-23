unit Http.Context;

interface

uses
  Http.Core;

type
  THttpContext = class
  private
    FRequest: THttpRequest;
  public
    constructor Create(const ARequest: THttpRequest);
    property Request: THttpRequest read FRequest;
  end;

implementation

constructor THttpContext.Create(const ARequest: THttpRequest);
begin
  inherited Create;
  FRequest := ARequest;
end;

end.
