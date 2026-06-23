unit Http.ParameterBinder;

interface

uses
  System.SysUtils,
  System.Rtti,
  Http.Context,
  Http.ParameterDescriptor,
  Http.BodyBinder.Contract,
  Http.ParameterBinder.Contract;

type
  TParameterBinder = class(TInterfacedObject, IParameterBinder)
  private
    FBodyBinder: IHttpBodyBinder;
    
    function FromContext(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromRoute(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
    function BindFromQuery(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromHeader(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
    function FromBody(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
  public
    constructor Create(const ABodyBinder: IHttpBodyBinder);
    
    function Execute(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
  end;

implementation

uses
  Http.Parameter.Binding,
  Http.ValueConverter,
  AppExceptions;

constructor TParameterBinder.Create(const ABodyBinder: IHttpBodyBinder);
begin
  inherited Create;

  if ABodyBinder = nil then
    raise EMissingDependencyException.Create('Body binder is required.');

  FBodyBinder := ABodyBinder;
end;

function TParameterBinder.Execute(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
begin
  case ADescriptor.Source of
    psContext:
      Exit(FromContext(AContext, ADescriptor));

    psRoute:
      Exit(FromRoute(AContext, ADescriptor));

    psQuery:
      Exit(BindFromQuery(AContext, ADescriptor));

    psHeader:
      Exit(FromHeader(AContext, ADescriptor));

    psBody:
      Exit(FromBody(AContext, ADescriptor));
  end;

  raise EBinderException.CreateFmt(
    'Unsupported binding source for parameter "%s".',
    [ADescriptor.Name]
  );
end;

function TParameterBinder.FromContext(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
begin
  if ADescriptor.ParameterType.Handle <> TypeInfo(THttpContext) then
    raise EBinderException.CreateFmt(
      'Parameter "%s" marked as FromContext must be THttpContext.',
      [ADescriptor.Name]
    );

  Result := TValue.From<THttpContext>(AContext);
end;

function TParameterBinder.FromRoute(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not AContext.Request.RouteParams.TryGetValue(ADescriptor.SourceName, RawValue) then
    raise EBinderException.CreateFmt(
      'Route parameter "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Route parameter "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.BindFromQuery(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not AContext.Request.QueryParams.TryGetValue(ADescriptor.SourceName, RawValue) then
    raise EBinderException.CreateFmt(
      'Query parameter "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Query parameter "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.FromHeader(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
var
  RawValue: string;
  HeaderName: string;
  ErrorMessage: string;
begin
  HeaderName := LowerCase(ADescriptor.SourceName);

  if not AContext.Request.Headers.TryGetValue(HeaderName, RawValue) then
    raise EBinderException.CreateFmt(
      'Header "%s" is required.',
      [ADescriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    ADescriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Header "%s" %s.',
      [ADescriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.FromBody(const AContext: THttpContext; const ADescriptor: TParameterDescriptor): TValue;
begin
  Result := FBodyBinder.Execute(
    AContext.Request.Body,
    ADescriptor.ParameterType
  );
end;

end.
