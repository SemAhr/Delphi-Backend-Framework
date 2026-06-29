unit Http.ActionInvoker;

interface

uses
  System.SysUtils,
  System.Rtti,
  Container.App,
  Http.Context,
  Http.RouteDescriptor,
  Http.ParameterBinder.Port,
  Http.ActionInvoker.Port;

type
  TActionInvoker = class(TInterfacedObject, IActionInvoker)
  private
    FContainer: TAppContainer;
    FParameterBinder: IParameterBinder;
  public
    constructor Create(const AContainer: TAppContainer; const AParameterBinder: IParameterBinder);

    function Execute(const ARoute: TRouteDescriptor; const AContext: TContext): TValue;
  end;

implementation

uses
  AppExceptions;

constructor TActionInvoker.Create(const AContainer: TAppContainer; const AParameterBinder: IParameterBinder);
begin
  inherited Create;

  if AContainer = nil then
    raise EMissingDependencyException.Create('Container is required.');

  if AParameterBinder = nil then
    raise EMissingDependencyException.Create('Parameter binder is required.');

  FContainer := AContainer;
  FParameterBinder := AParameterBinder;
end;

function TActionInvoker.Execute(const ARoute: TRouteDescriptor; const AContext: TContext): TValue;
var
  Arguments: TArray<TValue>;
begin
  var Resolver: TObject := AContext.Dependencies;

  if Resolver = nil then
    Resolver := FContainer;

  var Controller := FContainer.CreateComponentInstance(ARoute.ControllerType.MetaclassType, Resolver);

  if Controller = nil then
    raise EMissingDependencyException.CreateFmt(
      'Controller "%s" could not be created.',
      [ARoute.ControllerType.Name]
    );

  try
    SetLength(Arguments, Length(ARoute.Parameters));

    for var Index := 0 to High(ARoute.Parameters) do
      Arguments[Index] := FParameterBinder.Execute(AContext, ARoute.Parameters[Index]);

    Result := ARoute.MethodInfo.Invoke(Controller, Arguments);
  finally
    Controller.Free;
  end;
end;

end.
