unit Http.Router;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Container.Port,
  Http.Core,
  Http.RouteDescriptor,
  Http.Router.Port,
  Http.ActionInvoker.Port;

type
  TRouter = class(TInterfacedObject, IRouter)
  private
    FRoutes: TObjectList<TRouteDescriptor>;
    FActionInvoker: IActionInvoker;
    FContainer: IContainer;

    function SplitPath(const AValue: string): TArray<string>;

    function MatchPath(
      const APattern: string;
      const APath: string;
      const AParams: TDictionary<string, string>
    ): Boolean;

    function InvokeRoute(const ARoute: TRouteDescriptor; const ARequest: TRequest): TResponse;
  public
    constructor Create(
      const ARoutes: TObjectList<TRouteDescriptor>;
      const AActionInvoker: IActionInvoker;
      const AContainer: IContainer
    );
    destructor Destroy; override;

    function Dispatch(const ARequest: TRequest): TResponse;
  end;

implementation

uses
  AppExceptions,
  Http.Attributes,
  Http.Context,
  Dto.Port,
  Json.Helpers;

constructor TRouter.Create(
  const ARoutes: TObjectList<TRouteDescriptor>;
  const AActionInvoker: IActionInvoker;
  const AContainer: IContainer
);
begin
  inherited Create;

  if ARoutes = nil then
    raise EMissingDependencyException.Create('Routes are required.');

  if AActionInvoker = nil then
    raise EMissingDependencyException.Create('Action invoker is required.');

  if AContainer = nil then
    raise EMissingDependencyException.Create('Container is required.');

  FRoutes := ARoutes;
  FActionInvoker := AActionInvoker;
  FContainer := AContainer;
end;

destructor TRouter.Destroy;
begin
  FRoutes.Free;
  inherited;
end;

function TRouter.SplitPath(const AValue: string): TArray<string>;
var
  CleanValue: string;
begin
  CleanValue := AValue.Trim(['/']);

  if CleanValue = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  Result := CleanValue.Split(['/']);
end;

function TRouter.MatchPath(
  const APattern: string;
  const APath: string;
  const AParams: TDictionary<string, string>
): Boolean;
var
  PatternParts: TArray<string>;
  PathParts: TArray<string>;
  I: Integer;
  PatternPart: string;
  ParamName: string;
begin
  AParams.Clear;

  PatternParts := SplitPath(APattern);
  PathParts := SplitPath(APath);

  if Length(PatternParts) <> Length(PathParts) then
    Exit(False);

  for I := 0 to High(PatternParts) do
  begin
    PatternPart := PatternParts[I];

    if PatternPart.StartsWith(':') then
    begin
      ParamName := PatternPart.Substring(1);

      if ParamName = '' then
        raise Exception.CreateFmt(
          'Invalid route parameter in pattern "%s".',
          [APattern]
        );

      AParams.AddOrSetValue(ParamName, PathParts[I]);
      Continue;
    end;

    if not SameText(PatternPart, PathParts[I]) then
      Exit(False);
  end;

  Result := True;
end;

function TRouter.InvokeRoute(const ARoute: TRouteDescriptor; const ARequest: TRequest): TResponse;
var
  ReturnValue: TValue;
  ReturnedObject: TObject;
  Response: TResponse;
  StatusCode: Integer;
begin
  StatusCode := 0;

  for var Attribute in ARoute.MethodInfo.GetAttributes do
  begin
    if Attribute is StatusCodeAttribute then
    begin
      StatusCode := StatusCodeAttribute(Attribute).StatusCode;
      Break;
    end;
  end;

  var Scope := FContainer.CreateScope;
  var Context := TContext.Create(ARequest, Scope);
  try
    ReturnValue := FActionInvoker.Execute(ARoute, Context);
  finally
    Context.Free;
  end;

  if ReturnValue.IsEmpty then
  begin
    Response := TResponse.NoContent;

    if StatusCode > 0 then
      Response.StatusCode := StatusCode;

    Exit(Response);
  end;

  if ReturnValue.Kind <> tkClass then
    raise EInvalidAttributeException.CreateFmt(
      'Invalid route return type. Expected %s or IDto, received %s.',
      [
        TResponse.ClassName,
        ReturnValue.TypeInfo.Name
      ]
    );

  ReturnedObject := ReturnValue.AsObject;

  if ReturnedObject = nil then
  begin
    Response := TResponse.NoContent;

    if StatusCode > 0 then
      Response.StatusCode := StatusCode;

    Exit(Response);
  end;

  if ReturnedObject is TResponse then
    Response := TResponse(ReturnedObject)
  else if Supports(ReturnedObject, IDto) then
    Response := TResponse.Json(TJsonHelpers.ToString(ReturnedObject))
  else
    raise EInvalidAttributeException.CreateFmt(
      'Invalid route return type. Expected %s or an object implementing IDto, received %s.',
      [
        TResponse.ClassName,
        ReturnedObject.ClassName
      ]
    );

  if StatusCode > 0 then
    Response.StatusCode := StatusCode;

  Result := Response;
end;

function TRouter.Dispatch(const ARequest: TRequest): TResponse;
begin
  for var Route in FRoutes do
  begin
    if not SameText(Route.Method, ARequest.Method) then
      Continue;

    if MatchPath(Route.Path, ARequest.Path, ARequest.RouteParams) then
      Exit(InvokeRoute(Route, ARequest));
  end;

  raise ENotFoundAppException.Create('Route not found');
end;

end.
