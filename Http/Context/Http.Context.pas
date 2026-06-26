unit Http.Context;

interface

uses
  Container.Port,
  Http.Core;

type
  TContext = class
  private
    FRequest: TRequest;
    FServices: IContainer;
  public
    constructor Create(const ARequest: TRequest; const AServices: IContainer);

    property Request: TRequest read FRequest;
    property Services: IContainer read FServices;
  end;

implementation

constructor TContext.Create(const ARequest: TRequest; const AServices: IContainer);
begin
  inherited Create;
  FRequest := ARequest;
  FServices := AServices;
end;

end.
