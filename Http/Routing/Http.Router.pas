unit Http.Router;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Http.Core,
  Http.RouteDescriptor,
  Http.Router.Contract,
  Http.ActionInvoker.Contract;

type
  TRouter = class(TInterfacedObject, IRouter)
  private
    FRoutes: TObjectList<TRouteDescriptor>;
    FActionInvoker: IActionInvoker;
    
    function SplitPath(const AValue: string): TArray<string>;
    
    function MatchPath(
      const APattern: string;
      const APath: string;
      const AParams: TDictionary<string, string>
    ): Boolean;
    
    function InvokeRoute(const ARoute: TRouteDescriptor; const ARequest: THttpRequest): THttpResponse;
  public
    constructor Create(const ARoutes: TObjectList<TRouteDescriptor>; const AActionInvoker: IActionInvoker);
    destructor Destroy; override;
    
    function Dispatch(const ARequest: THttpRequest): THttpResponse;
  end;

implementation

uses
  AppExceptions,
  Http.Context;

constructor TRouter.Create(const ARoutes: TObjectList<TRouteDescriptor>; const AActionInvoker: IActionInvoker);
begin
  inherited Create;

  if ARoutes = nil then
    raise EMissingDependencyException.Create('Routes are required.');

  if AActionInvoker = nil then
    raise EMissingDependencyException.Create('Action invoker is required.');

  FRoutes := ARoutes;
  FActionInvoker := AActionInvoker;
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

function TRouter.InvokeRoute(const ARoute: TRouteDescriptor; const ARequest: THttpRequest): THttpResponse;
var
  ReturnValue: TValue;
begin
  var Context := THttpContext.Create(ARequest);
  try
    ReturnValue := FActionInvoker.Execute(ARoute, Context);
  finally
    Context.Free;
  end;

  if ReturnValue.IsEmpty then
    Exit(THttpResponse.NoContent);

  Result := ReturnValue.AsType<THttpResponse>;
end;

function TRouter.Dispatch(const ARequest: THttpRequest): THttpResponse;
begin
  for var Route in FRoutes do
  begin
    if not SameText(Route.Method, ARequest.Method) then
      Continue;

    if MatchPath(Route.Path, ARequest.Path, ARequest.RouteParams) then
      Exit(InvokeRoute(Route, ARequest));
  end;

  Result := THttpResponse.Json(
    '{"error":"Route not found"}',
    404
  );
end;

end.
