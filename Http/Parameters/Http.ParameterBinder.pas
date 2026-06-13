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

    function BindFromContext(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;

    function BindFromRoute(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;

    function BindFromQuery(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;

    function BindFromHeader(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;

    function BindFromBody(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;

  public
    constructor Create(const ABodyBinder: IHttpBodyBinder);

    function Bind(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;
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

function TParameterBinder.Bind(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
begin
  case Descriptor.Source of
    psContext:
      Exit(BindFromContext(Context, Descriptor));

    psRoute:
      Exit(BindFromRoute(Context, Descriptor));

    psQuery:
      Exit(BindFromQuery(Context, Descriptor));

    psHeader:
      Exit(BindFromHeader(Context, Descriptor));

    psBody:
      Exit(BindFromBody(Context, Descriptor));
  end;

  raise EBinderException.CreateFmt(
    'Unsupported binding source for parameter "%s".',
    [Descriptor.Name]
  );
end;

function TParameterBinder.BindFromContext(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
begin
  if Descriptor.ParameterType.Handle <> TypeInfo(THttpContext) then
    raise EBinderException.CreateFmt(
      'Parameter "%s" marked as FromContext must be THttpContext.',
      [Descriptor.Name]
    );

  Result := TValue.From<THttpContext>(Context);
end;

function TParameterBinder.BindFromRoute(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not Context.Request.RouteParams.TryGetValue(Descriptor.SourceName, RawValue) then
    raise EBinderException.CreateFmt(
      'Route parameter "%s" is required.',
      [Descriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    Descriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Route parameter "%s" %s.',
      [Descriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.BindFromQuery(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
var
  RawValue: string;
  ErrorMessage: string;
begin
  if not Context.Request.QueryParams.TryGetValue(Descriptor.SourceName, RawValue) then
    raise EBinderException.CreateFmt(
      'Query parameter "%s" is required.',
      [Descriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    Descriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Query parameter "%s" %s.',
      [Descriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.BindFromHeader(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
var
  RawValue: string;
  HeaderName: string;
  ErrorMessage: string;
begin
  HeaderName := LowerCase(Descriptor.SourceName);

  if not Context.Request.Headers.TryGetValue(HeaderName, RawValue) then
    raise EBinderException.CreateFmt(
      'Header "%s" is required.',
      [Descriptor.SourceName]
    );

  if not TValueConverter.TryConvertString(
    RawValue,
    Descriptor.ParameterType,
    Result,
    ErrorMessage
  ) then
    raise EBinderException.CreateFmt(
      'Header "%s" %s.',
      [Descriptor.SourceName, ErrorMessage]
    );
end;

function TParameterBinder.BindFromBody(
  const Context: THttpContext;
  const Descriptor: TParameterDescriptor
): TValue;
begin
  Result := FBodyBinder.BindBody(
    Context.Request.Body,
    Descriptor.ParameterType
  );
end;

end.
