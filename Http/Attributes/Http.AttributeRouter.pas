unit Http.AttributeRouter;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Common.Container.Contract,
  Http.Core,
  Http.RouteDescriptor;

type
  TAttributeRouter = class
  private
    FRoutes: TObjectList<TRouteDescriptor>;
    FContainer: IContainer;

    function SplitPath(const Value: string): TArray<string>;

    function MatchPath(
      const Pattern: string;
      const Path: string;
      const Params: TDictionary<string, string>
    ): Boolean;

    function InvokeRoute(
      const Route: TRouteDescriptor;
      const Request: THttpRequest
    ): THttpResponse;

  public
    constructor Create(
      const ARoutes: TObjectList<TRouteDescriptor>;
      const AContainer: IContainer
    );

    destructor Destroy; override;

    function Dispatch(const Request: THttpRequest): THttpResponse;
  end;

implementation

constructor TAttributeRouter.Create(
  const ARoutes: TObjectList<TRouteDescriptor>;
  const AContainer: IContainer
);
begin
  inherited Create;
  FRoutes := ARoutes;
  FContainer := AContainer;
end;

destructor TAttributeRouter.Destroy;
begin
  FRoutes.Free;
  inherited;
end;

function TAttributeRouter.SplitPath(const Value: string): TArray<string>;
var
  CleanValue: string;
begin
  CleanValue := Value.Trim(['/']);

  if CleanValue = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  Result := CleanValue.Split(['/']);
end;

function TAttributeRouter.MatchPath(
  const Pattern: string;
  const Path: string;
  const Params: TDictionary<string, string>
): Boolean;
var
  PatternParts: TArray<string>;
  PathParts: TArray<string>;
  I: Integer;
  PatternPart: string;
  ParamName: string;
begin
  Params.Clear;

  PatternParts := SplitPath(Pattern);
  PathParts := SplitPath(Path);

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
          [Pattern]
        );

      Params.AddOrSetValue(ParamName, PathParts[I]);
      Continue;
    end;

    if not SameText(PatternPart, PathParts[I]) then
      Exit(False);
  end;

  Result := True;
end;

function TAttributeRouter.InvokeRoute(
  const Route: TRouteDescriptor;
  const Request: THttpRequest
): THttpResponse;
var
  Controller: TObject;
  ReturnValue: TValue;
begin
  Controller := FContainer.Resolve(Route.ControllerType.Handle);

  if Controller = nil then
    raise Exception.CreateFmt(
      'Could not resolve controller "%s".',
      [Route.ControllerType.Name]
    );

  ReturnValue := Route.MethodInfo.Invoke(
    Controller,
    [TValue.From<THttpRequest>(Request)]
  );

  if ReturnValue.IsEmpty then
    Exit(THttpResponse.NoContent);

  Result := ReturnValue.AsType<THttpResponse>;
end;

function TAttributeRouter.Dispatch(
  const Request: THttpRequest
): THttpResponse;
var
  Route: TRouteDescriptor;
begin
  for Route in FRoutes do
  begin
    if not SameText(Route.Method, Request.Method) then
      Continue;

    if MatchPath(Route.Path, Request.Path, Request.RouteParams) then
      Exit(InvokeRoute(Route, Request));
  end;

  Result := THttpResponse.Json(
    '{"error":"Route not found"}',
    404
  );
end;

end.
