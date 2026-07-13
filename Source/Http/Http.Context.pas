unit Http.Context;

interface

uses
  Container.Scope,
  Http.Core;

type
  TContext = class
  private
    FRequest: TRequest;
    FDependencies: TContainerScope;
  public
    constructor Create(const ARequest: TRequest; const ADependencies: TContainerScope);

    property Request: TRequest read FRequest;
    property Dependencies: TContainerScope read FDependencies;
  end;

implementation

constructor TContext.Create(const ARequest: TRequest; const ADependencies: TContainerScope);
begin
  inherited Create;
  FRequest := ARequest;
  FDependencies := ADependencies;
end;

end.
