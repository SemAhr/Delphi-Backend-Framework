unit Http.ParameterBinder;

interface

uses
  System.SysUtils,
  System.Rtti,
  Http.Context,
  Http.ParameterDescriptor,
  Http.BodyBinder.Port,
  Http.ParameterBinder.Port,
  Dto.Port;

type
  TParameterBinder = class(TInterfacedObject, IParameterBinder)
  private
    FBodyBinder: IBodyBinder;

    function FromContext(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromRoute(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromQuery(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromHeader(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromBody(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
  public
    constructor Create(const ABodyBinder: IBodyBinder);

    function Execute(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
  end;

implementation

uses
  Http.Parameter.Binding,
  Http.ValueConverter,
  AppExceptions;

constructor TParameterBinder.Create(const ABodyBinder: IBodyBinder);
begin
  inherited Create;

  if ABodyBinder = nil then
    raise EMissingDependencyException.Create('Body binder is required.');

  FBodyBinder := ABodyBinder;
end;

function TParameterBinder.Execute(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
begin
  case ADescriptor.Source of
    psContext:
      Exit(FromContext(AContext, ADescriptor));

    psRoute:
      Exit(FromRoute(AContext, ADescriptor));

    psQuery:
      Exit(FromQuery(AContext, ADescriptor));

    psHeader:
      Exit(FromHeader(AContext, ADescriptor));

    psBody:
      Exit(FromBody(AContext, ADescriptor));
  end;

  raise EBadRequestAppException.CreateFmt(
    'Unsupported binding source for parameter "%s".',
    [ADescriptor.Name]
  );
end;

function TParameterBinder.FromContext(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
begin
  if ADescriptor.ParameterType.Handle <> TypeInfo(TContext) then
    raise EBadRequestAppException.CreateFmt(
      'Parameter "%s" marked as FromContext must be THttpContext.',
      [ADescriptor.Name]
    );

  Result := TValue.From<TContext>(AContext);
end;

function TParameterBinder.FromRoute(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not AContext.Request.RouteParams.TryGetValue(ADescriptor.SourceName, RawValue) then
    raise EBadRequestAppException.CreateFmt(
      'Route parameter "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBadRequestAppException.CreateFmt(
      'Route parameter "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.FromQuery(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not AContext.Request.QueryParams.TryGetValue(ADescriptor.SourceName, RawValue) then
    raise EBadRequestAppException.CreateFmt(
      'Query parameter "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBadRequestAppException.CreateFmt(
      'Query parameter "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.FromHeader(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  var HeaderName := LowerCase(ADescriptor.SourceName);

  if not AContext.Request.Headers.TryGetValue(HeaderName, RawValue) then
    raise EBadRequestAppException.CreateFmt(
      'Header "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBadRequestAppException.CreateFmt(
      'Header "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.FromBody(const AContext: TContext; const ADescriptor: TParameterDescriptor): TValue;
var
  Dto: IDto;
begin
  Dto := FBodyBinder.Execute(AContext.Request.Body, ADescriptor.ParameterType);
  TValue.Make(@Dto, ADescriptor.ParameterType.Handle, Result);
end;

end.
