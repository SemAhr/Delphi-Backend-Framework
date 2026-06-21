unit Http.ActionInvoker;

interface

uses
  System.SysUtils,
  System.Rtti,
  Container.Contract,
  Http.Context,
  Http.RouteDescriptor,
  Http.ParameterBinder.Contract,
  Http.ActionInvoker.Contract;

type
  TControllerActionInvoker = class(TInterfacedObject, IControllerActionInvoker)
  private
    FContainer: IContainer;
    FParameterBinder: IParameterBinder;

  public
    constructor Create(
      const AContainer: IContainer;
      const AParameterBinder: IParameterBinder
    );

    function Invoke(
      const ARoute: TRouteDescriptor;
      const AContext: THttpContext
    ): TValue;
  end;

implementation

uses
  AppExceptions;

constructor TControllerActionInvoker.Create(
  const AContainer: IContainer;
  const AParameterBinder: IParameterBinder
);
begin
  inherited Create;

  if AContainer = nil then
    raise EMissingDependencyException.Create('Container is required.');

  if AParameterBinder = nil then
    raise EMissingDependencyException.Create('Parameter binder is required.');

  FContainer := AContainer;
  FParameterBinder := AParameterBinder;
end;

function TControllerActionInvoker.Invoke(
  const ARoute: TRouteDescriptor;
  const AContext: THttpContext
): TValue;
var
  Controller: TObject;
  Arguments: TArray<TValue>;
  Index: Integer;
begin
  Controller := FContainer.Resolve(ARoute.ControllerType.Handle);

  if Controller = nil then
    raise EMissingDependencyException.CreateFmt(
      'Controller "%s" could not be resolved.',
      [ARoute.ControllerType.Name]
    );

  SetLength(Arguments, Length(ARoute.Parameters));

  for Index := 0 to High(ARoute.Parameters) do
    Arguments[Index] := FParameterBinder.Bind(AContext, ARoute.Parameters[Index]);

  Result := ARoute.MethodInfo.Invoke(Controller, Arguments);
end;

end.
