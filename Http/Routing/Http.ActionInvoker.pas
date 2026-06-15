unit Http.ActionInvoker;

interface

uses
  System.SysUtils,
  System.Rtti,
  Shared.Container.Contract,
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
      const Route: TRouteDescriptor;
      const Context: THttpContext
    ): TValue;
  end;

implementation

uses
  Shared.AppExceptions;

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
  const Route: TRouteDescriptor;
  const Context: THttpContext
): TValue;
var
  Controller: TObject;
  Arguments: TArray<TValue>;
  Index: Integer;
begin
  Controller := FContainer.Resolve(Route.ControllerType.Handle);

  if Controller = nil then
    raise EMissingDependencyException.CreateFmt(
      'Controller "%s" could not be resolved.',
      [Route.ControllerType.Name]
    );

  SetLength(Arguments, Length(Route.Parameters));

  for Index := 0 to High(Route.Parameters) do
    Arguments[Index] := FParameterBinder.Bind(Context, Route.Parameters[Index]);

  Result := Route.MethodInfo.Invoke(Controller, Arguments);
end;

end.
