unit Http.ActionInvoker;

interface

uses
  System.SysUtils,
  System.Rtti,
  Container.Port,
  Http.Context,
  Http.RouteDescriptor,
  Http.ParameterBinder.Port,
  Http.ActionInvoker.Port;

type
  TActionInvoker = class(TInterfacedObject, IActionInvoker)
  private
    FContainer: IContainer;
    FParameterBinder: IParameterBinder;
  public
    constructor Create(const AContainer: IContainer; const AParameterBinder: IParameterBinder);

    function Execute(const ARoute: TRouteDescriptor; const AContext: THttpContext): TValue;
  end;

implementation

uses
  AppExceptions;

constructor TActionInvoker.Create(const AContainer: IContainer; const AParameterBinder: IParameterBinder);
begin
  inherited Create;

  if AContainer = nil then
    raise EMissingDependencyException.Create('Container is required.');

  if AParameterBinder = nil then
    raise EMissingDependencyException.Create('Parameter binder is required.');

  FContainer := AContainer;
  FParameterBinder := AParameterBinder;
end;

function TActionInvoker.Execute(const ARoute: TRouteDescriptor; const AContext: THttpContext): TValue;
var
  Arguments: TArray<TValue>;
begin
  var Controller := FContainer.Resolve(ARoute.ControllerType.Handle);

  if Controller = nil then
    raise EMissingDependencyException.CreateFmt(
      'Controller "%s" could not be resolved.',
      [ARoute.ControllerType.Name]
    );

  SetLength(Arguments, Length(ARoute.Parameters));

  for var Index := 0 to High(ARoute.Parameters) do
    Arguments[Index] := FParameterBinder.Execute(AContext, ARoute.Parameters[Index]);

  Result := ARoute.MethodInfo.Invoke(Controller, Arguments);
end;

end.
