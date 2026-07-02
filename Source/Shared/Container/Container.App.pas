unit Container.App;

interface

uses
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  Container.DependencyDescriptor,
  Container.Scope,
  Options.Port,
  Http.Controller.Port,
  Http.Middleware.Descriptor;

type
  TOptionsValueLoader = reference to function: TValue;
  TOptionsRegistration = reference to procedure(const ARootOptions: TValue);

  /// <summary>
  /// Root dependency container used to configure the application.
  /// </summary>
  /// <remarks>
  /// TAppContainer owns dependency registrations, singleton instances, and the list of controllers
  /// that should be scanned for routes. Request-specific state is intentionally delegated to
  /// TContainerScope so scoped dependencies do not leak across HTTP requests.
  /// </remarks>
  TAppContainer = class
  private
    FDescriptors: TObjectDictionary<PTypeInfo, TDependencyDescriptor>;
    FControllerTypes: TList<TClass>;
    FGlobalMiddlewares: TList<TMiddlewareDescriptor>;
    FAttributeHandlerTypes: TList<TClass>;
    FOptionsRegistrations: TList<TOptionsRegistration>;
    FOptionsRootLoader: TOptionsValueLoader;
    FOptionsRootValue: TValue;
    FOptionsLoaded: Boolean;

    /// <summary>
    /// Converts class RTTI into a TClass value used by generic registration methods.
    /// </summary>
    function GetClassType(const ATypeInfo: PTypeInfo): TClass;

    /// <summary>
    /// Adds or replaces a dependency descriptor in the root registration table.
    /// </summary>
    procedure AddDescriptor(const ADescriptor: TDependencyDescriptor);

    /// <summary>
    /// Finds the public Create constructor with the largest parameter list for constructor injection.
    /// </summary>
    function FindConstructor(const AImplementationType: TClass): TRttiMethod;

    /// <summary>
    /// Resolves one constructor parameter and converts it into the TValue required by RTTI invocation.
    /// </summary>
    function ResolveDependency(const ATypeInfo: PTypeInfo; const AResolver: TObject): TObject;

    function ResolveConstructorParameter(const AParameter: TRttiParameter; const AResolver: TObject): TValue;

    function ExtractOptionValue<TOptions: record>(const ARootOptions: TValue; const AName: string): TOptions;
    procedure EnsureOptionsLoaded;

    function ImplementsInterfaceContract(const AType: TClass; const AInterfaceType: PTypeInfo): Boolean;
  public
    /// <summary>
    /// Creates an empty root container ready to receive dependency and controller registrations.
    /// </summary>
    constructor Create;

    /// <summary>
    /// Releases descriptors, singleton instances owned by descriptors, and controller metadata.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Returns the controller classes registered through AddController.
    /// </summary>
    /// <remarks>
    /// HTTP composition uses this list to scan routes without requiring the application to manually
    /// pass an array of controller classes to the scanner.
    /// </remarks>
    function GetControllerTypes: TArray<TClass>;

    function GetGlobalMiddlewares: TArray<TMiddlewareDescriptor>;

    function GetAttributeHandlerTypes: TArray<TClass>;

    /// <summary>
    /// Creates an object instance from a descriptor using a factory or constructor injection.
    /// </summary>
    /// <remarks>
    /// This method is public so request scopes can reuse the root container's construction logic
    /// while still resolving nested dependencies from the current scope.
    /// </remarks>
    function CreateInstance(const ADescriptor: TDependencyDescriptor; const AResolver: TObject): TObject;

    function CreateComponentInstance(const AImplementationType: TClass; const AResolver: TObject): TObject;

    /// <summary>
    /// Gets the descriptor registered for a dependency type.
    /// </summary>
    /// <exception cref="EMissingDependencyException">Raised when the dependency is not registered.</exception>
    function GetDescriptor(const ATypeInfo: PTypeInfo): TDependencyDescriptor;

    /// <summary>
    /// Compatibility helper that registers an already-created singleton instance.
    /// </summary>
    procedure RegisterInstance(const ATypeInfo: PTypeInfo; const AInstance: TObject);

    /// <summary>
    /// Registers a lazy singleton by RTTI type and implementation class.
    /// </summary>
    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass); overload;

    /// <summary>
    /// Registers an already-created singleton instance owned by the container.
    /// </summary>
    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject); overload;

    /// <summary>
    /// Registers a lazy singleton using generic type parameters.
    /// </summary>
    procedure AddSingleton<TDependency; TImplementation: class>; overload;

    /// <summary>
    /// Registers a transient dependency by RTTI type and implementation class.
    /// </summary>
    procedure AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass); overload;

    /// <summary>
    /// Registers a transient dependency using generic type parameters.
    /// </summary>
    procedure AddTransient<TDependency; TImplementation: class>; overload;

    /// <summary>
    /// Registers a scoped dependency by RTTI type and implementation class.
    /// </summary>
    procedure AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass); overload;

    /// <summary>
    /// Registers a scoped dependency using generic type parameters.
    /// </summary>
    procedure AddScoped<TDependency; TImplementation: class>; overload;

    /// <summary>
    /// Defines the root application options loader. The loader is executed only once, lazily.
    /// </summary>
    procedure SetOptionsLoader<TRootOptions: record>(const ALoader: TOptionsLoader<TRootOptions>);

    /// <summary>
    /// Registers a record options section by field name from the root options record.
    /// </summary>
    procedure AddOptions<TOptions: record>(const AName: string);

    /// <summary>
    /// Registers a controller class and stores it for automatic route discovery.
    /// </summary>
    /// <remarks>
    /// Controllers are HTTP framework components. They are not registered as dependencies in the DI registry.
    /// </remarks>
    procedure AddController(const AControllerType: TClass);

    /// <summary>
    /// Registers multiple controller classes in a single call.
    /// </summary>
    procedure AddControllers(const AControllerTypes: array of TClass);

    /// <summary>
    /// Adds a global middleware class to the HTTP pipeline.
    /// </summary>
    procedure Use(const AMiddlewareType: TClass); overload;

    /// <summary>
    /// Adds multiple global middleware classes to the HTTP pipeline preserving registration order.
    /// </summary>
    procedure Use(const AMiddlewareTypes: array of TClass); overload;

    /// <summary>
    /// Registers an endpoint attribute handler class used by custom attributes.
    /// </summary>
    procedure AddAttributeHandler(const AHandlerType: TClass);

    /// <summary>
    /// Registers multiple endpoint attribute handler classes in a single call.
    /// </summary>
    procedure AddAttributeHandlers(const AHandlerTypes: array of TClass);

    /// <summary>
    /// Registers a dependency with custom construction logic and an explicit lifetime.
    /// </summary>
    procedure AddFactory(
      const ATypeInfo: PTypeInfo;
      const AFactory: TDependencyFactory;
      const ALifetime: TDependencyLifetime
    );

    /// <summary>
    /// Resolves a dependency from the root container.
    /// </summary>
    /// <remarks>
    /// Singleton and transient dependencies can be resolved from the root container. Scoped
    /// dependencies must be resolved from a scope created with CreateScope.
    /// </remarks>
    function Resolve(const ATypeInfo: PTypeInfo): TObject;

    /// <summary>
    /// Creates a scope for resolving dependencies that live for a single request/operation.
    /// </summary>
    function CreateScope: TContainerScope;
  end;

implementation

uses
  System.SysUtils,
  AppExceptions,
  App.Options,
  App.Options.Loader,
  Logger.Options,
  Http.Middleware.Port,
  Http.EndpointAttributeHandler.Port;

constructor TAppContainer.Create;
begin
  inherited Create;
  FDescriptors := TObjectDictionary<PTypeInfo, TDependencyDescriptor>.Create([doOwnsValues]);
  FControllerTypes := TList<TClass>.Create;
  FGlobalMiddlewares := TList<TMiddlewareDescriptor>.Create;
  FAttributeHandlerTypes := TList<TClass>.Create;
  FOptionsRegistrations := TList<TOptionsRegistration>.Create;
  FOptionsLoaded := False;

  SetOptionsLoader<TAppOptions>(TAppOptionsLoader.LoadFromDefaultPath);
  AddOptions<TLoggerOptions>('Logger');
end;

destructor TAppContainer.Destroy;
begin
  FOptionsRegistrations.Free;
  FAttributeHandlerTypes.Free;
  FGlobalMiddlewares.Free;
  FControllerTypes.Free;
  FDescriptors.Free;
  inherited;
end;

function TAppContainer.GetClassType(const ATypeInfo: PTypeInfo): TClass;
begin
  if (ATypeInfo = nil) or (ATypeInfo.Kind <> tkClass) then
    raise EMissingDependencyException.Create('Class type info is required.');

  Result := GetTypeData(ATypeInfo).ClassType;
end;

function TAppContainer.GetControllerTypes: TArray<TClass>;
begin
  Result := FControllerTypes.ToArray;
end;

function TAppContainer.GetGlobalMiddlewares: TArray<TMiddlewareDescriptor>;
begin
  Result := FGlobalMiddlewares.ToArray;
end;

function TAppContainer.GetAttributeHandlerTypes: TArray<TClass>;
begin
  Result := FAttributeHandlerTypes.ToArray;
end;

function TAppContainer.ImplementsInterfaceContract(const AType: TClass; const AInterfaceType: PTypeInfo): Boolean;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  InterfaceGuid: TGUID;
begin
  Result := False;

  if (AType = nil) or (AInterfaceType = nil) then
    Exit;

  InterfaceGuid := GetTypeData(AInterfaceType).Guid;

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  if not (RttiType is TRttiInstanceType) then
    Exit;

  for var InterfaceType in TRttiInstanceType(RttiType).GetImplementedInterfaces do
  begin
    if InterfaceType.GUID = InterfaceGuid then
      Exit(True);
  end;
end;

function TAppContainer.ExtractOptionValue<TOptions>(const ARootOptions: TValue; const AName: string): TOptions;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Field: TRttiField;
  FieldValue: TValue;
begin
  if ARootOptions.IsEmpty then
    raise EMissingDependencyException.Create('Root options are not loaded.');

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(ARootOptions.TypeInfo);

  if (RttiType = nil) or (RttiType.TypeKind <> tkRecord) then
    raise EMissingDependencyException.Create('Root options must be a record.');

  Field := RttiType.GetField(AName);

  if Field = nil then
    raise EMissingDependencyException.CreateFmt(
      'Options field "%s" was not found in root options record.',
      [AName]
    );

  FieldValue := Field.GetValue(ARootOptions.GetReferenceToRawData);

  if FieldValue.TypeInfo <> TypeInfo(TOptions) then
    raise EMissingDependencyException.CreateFmt(
      'Options field "%s" has type "%s" but "%s" was expected.',
      [
        AName,
        FieldValue.TypeInfo.Name
      ]
    );

  Result := FieldValue.AsType<TOptions>;
end;

procedure TAppContainer.EnsureOptionsLoaded;
begin
  if FOptionsLoaded then
    Exit;

  if not Assigned(FOptionsRootLoader) then
    Exit;

  FOptionsRootValue := FOptionsRootLoader();

  for var Registration in FOptionsRegistrations do
    Registration(FOptionsRootValue);

  FOptionsLoaded := True;
end;

procedure TAppContainer.AddDescriptor(const ADescriptor: TDependencyDescriptor);
begin
  if ADescriptor.DependencyType = nil then
    raise EMissingDependencyException.Create('Dependency type is required.');

  FDescriptors.AddOrSetValue(ADescriptor.DependencyType, ADescriptor);
end;

function TAppContainer.GetDescriptor(const ATypeInfo: PTypeInfo): TDependencyDescriptor;
begin
  EnsureOptionsLoaded;

  if ATypeInfo = nil then
    raise EMissingDependencyException.Create('Dependency type is required.');

  if not FDescriptors.TryGetValue(ATypeInfo, Result) then
    raise EMissingDependencyException.CreateFmt(
      'Type "%s" was not registered in container.',
      [ATypeInfo.Name]
    );
end;

function TAppContainer.FindConstructor(const AImplementationType: TClass): TRttiMethod;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  BestParameterCount: Integer;
begin
  Result := nil;
  BestParameterCount := -1;

  if AImplementationType = nil then
    Exit;

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AImplementationType);

  for var Method in RttiType.GetMethods do
  begin
    if Method.MethodKind <> mkConstructor then
      Continue;

    if not SameText(Method.Name, 'Create') then
      Continue;

    if Method.Visibility <> mvPublic then
      Continue;

    var ParameterCount := Length(Method.GetParameters);

    if ParameterCount > BestParameterCount then
    begin
      Result := Method;
      BestParameterCount := ParameterCount;
    end;
  end;
end;

function TAppContainer.ResolveDependency(const ATypeInfo: PTypeInfo; const AResolver: TObject): TObject;
begin
  if AResolver is TContainerScope then
    Exit(TContainerScope(AResolver).Resolve(ATypeInfo));

  Result := Resolve(ATypeInfo);
end;

function TAppContainer.ResolveConstructorParameter(const AParameter: TRttiParameter; const AResolver: TObject): TValue;
var
  ParameterType: TRttiType;
  ResolvedObject: TObject;
  ResolvedInterface: IInterface;
begin
  ParameterType := AParameter.ParamType;

  if ParameterType = nil then
    raise EMissingDependencyException.CreateFmt(
      'Constructor parameter "%s" does not have RTTI type information.',
      [AParameter.Name]
    );

  ResolvedObject := ResolveDependency(ParameterType.Handle, AResolver);

  case ParameterType.TypeKind of
    tkClass:
      begin
        if ResolvedObject = nil then
          raise EMissingDependencyException.CreateFmt(
            'Constructor parameter "%s" could not be resolved.',
            [AParameter.Name]
          );

        TValue.Make(@ResolvedObject, ParameterType.Handle, Result);
      end;

    tkInterface:
      begin
        if (ResolvedObject = nil) or not Supports(
          ResolvedObject,
          TRttiInterfaceType(ParameterType).GUID,
          ResolvedInterface
        ) then
          raise EMissingDependencyException.CreateFmt(
            'Resolved dependency for constructor parameter "%s" does not implement "%s".',
            [AParameter.Name, ParameterType.Name]
          );

        TValue.Make(@ResolvedInterface, ParameterType.Handle, Result);
      end;
  else
    raise EMissingDependencyException.CreateFmt(
      'Constructor parameter "%s" has unsupported injectable type "%s".',
      [AParameter.Name, ParameterType.Name]
    );
  end;
end;

function TAppContainer.CreateInstance(const ADescriptor: TDependencyDescriptor; const AResolver: TObject): TObject;
begin
  if Assigned(ADescriptor.Factory) then
    Exit(ADescriptor.Factory(
      function(const ATypeInfo: PTypeInfo): TObject
      begin
        Result := ResolveDependency(ATypeInfo, AResolver);
      end
    ));

  if ADescriptor.ImplementationType = nil then
    raise EMissingDependencyException.CreateFmt(
      'Type "%s" does not have an implementation type or factory.',
      [ADescriptor.DependencyType.Name]
    );

  Result := CreateComponentInstance(ADescriptor.ImplementationType, AResolver);
end;

function TAppContainer.CreateComponentInstance(const AImplementationType: TClass; const AResolver: TObject): TObject;
var
  ConstructorMethod: TRttiMethod;
  Parameters: TArray<TRttiParameter>;
  Arguments: TArray<TValue>;
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  ConstructorMethod := FindConstructor(AImplementationType);

  if ConstructorMethod = nil then
    Exit(AImplementationType.Create);

  Parameters := ConstructorMethod.GetParameters;
  SetLength(Arguments, Length(Parameters));

  for var Index := 0 to High(Parameters) do
    Arguments[Index] := ResolveConstructorParameter(Parameters[Index], AResolver);

  Result := ConstructorMethod.Invoke(AImplementationType, Arguments).AsObject;
end;

procedure TAppContainer.RegisterInstance(const ATypeInfo: PTypeInfo; const AInstance: TObject);
begin
  AddSingleton(ATypeInfo, AInstance);
end;

procedure TAppContainer.AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TSingletonDependencyDescriptor.Create(ATypeInfo, AImplementationType, nil));
end;

procedure TAppContainer.AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject);
var
  Descriptor: TDependencyDescriptor;
begin
  if AInstance = nil then
    raise EMissingDependencyException.Create('Singleton instance is required.');

  Descriptor := TSingletonDependencyDescriptor.Create(ATypeInfo, AInstance.ClassType, nil);
  TSingletonDependencyDescriptor(Descriptor).Instance := AInstance;
  TSingletonDependencyDescriptor(Descriptor).OwnsInstance := True;

  AddDescriptor(Descriptor);
end;

procedure TAppContainer.AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TTransientDependencyDescriptor.Create(ATypeInfo, AImplementationType, nil));
end;

procedure TAppContainer.AddTransient<TDependency, TImplementation>;
begin
  AddTransient(TypeInfo(TDependency), GetClassType(TypeInfo(TImplementation)));
end;

procedure TAppContainer.AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TScopedDependencyDescriptor.Create(ATypeInfo, AImplementationType, nil));
end;

procedure TAppContainer.AddScoped<TDependency, TImplementation>;
begin
  AddScoped(TypeInfo(TDependency), GetClassType(TypeInfo(TImplementation)));
end;

procedure TAppContainer.AddSingleton<TDependency, TImplementation>;
begin
  AddSingleton(TypeInfo(TDependency), GetClassType(TypeInfo(TImplementation)));
end;

procedure TAppContainer.SetOptionsLoader<TRootOptions>(const ALoader: TOptionsLoader<TRootOptions>);
begin
  if not Assigned(ALoader) then
    raise EMissingDependencyException.Create('Options loader is required.');

  FOptionsRootLoader :=
    function: TValue
    var
      RootOptions: TRootOptions;
    begin
      RootOptions := ALoader();
      AddSingleton(TypeInfo(IOptions<TRootOptions>), TOptions<TRootOptions>.Create(RootOptions));
      Result := TValue.From<TRootOptions>(RootOptions);
    end;

  FOptionsLoaded := False;
end;

procedure TAppContainer.AddOptions<TOptions>(const AName: string);
begin
  if AName.Trim.IsEmpty then
    raise EMissingDependencyException.Create('Options name is required.');

  var Registration: TOptionsRegistration :=
    procedure(const ARootOptions: TValue)
    begin
      AddSingleton(
        TypeInfo(IOptions<TOptions>),
        TOptions<TOptions>.Create(ExtractOptionValue<TOptions>(ARootOptions, AName))
      );
    end;

  FOptionsRegistrations.Add(Registration);

  if FOptionsLoaded then
    Registration(FOptionsRootValue);
end;

procedure TAppContainer.AddController(const AControllerType: TClass);
begin
  if AControllerType = nil then
    raise EMissingDependencyException.Create('Controller type is required.');

  if not ImplementsInterfaceContract(AControllerType, TypeInfo(IController)) then
    raise EMissingDependencyException.CreateFmt(
      'Controller "%s" must implement IController.',
      [AControllerType.ClassName]
    );

  if FControllerTypes.IndexOf(AControllerType) < 0 then
    FControllerTypes.Add(AControllerType);
end;

procedure TAppContainer.AddControllers(const AControllerTypes: array of TClass);
begin
  for var ControllerType in AControllerTypes do
    AddController(ControllerType);
end;

procedure TAppContainer.Use(const AMiddlewareType: TClass);
begin
  if AMiddlewareType = nil then
    raise EMissingDependencyException.Create('Middleware type is required.');

  if not ImplementsInterfaceContract(AMiddlewareType, TypeInfo(IMiddleware)) then
    raise EMissingDependencyException.CreateFmt(
      'Middleware "%s" must implement IMiddleware.',
      [AMiddlewareType.ClassName]
    );

  FGlobalMiddlewares.Add(TMiddlewareDescriptor.Create(AMiddlewareType, FGlobalMiddlewares.Count));
end;

procedure TAppContainer.Use(const AMiddlewareTypes: array of TClass);
begin
  for var MiddlewareType in AMiddlewareTypes do
    Use(MiddlewareType);
end;

procedure TAppContainer.AddAttributeHandler(const AHandlerType: TClass);
begin
  if AHandlerType = nil then
    raise EMissingDependencyException.Create('Attribute handler type is required.');

  if not ImplementsInterfaceContract(AHandlerType, TypeInfo(IEndpointAttributeHandler)) then
    raise EMissingDependencyException.CreateFmt(
      'Attribute handler "%s" must implement IEndpointAttributeHandler.',
      [AHandlerType.ClassName]
    );

  if FAttributeHandlerTypes.IndexOf(AHandlerType) < 0 then
    FAttributeHandlerTypes.Add(AHandlerType);
end;

procedure TAppContainer.AddAttributeHandlers(const AHandlerTypes: array of TClass);
begin
  for var HandlerType in AHandlerTypes do
    AddAttributeHandler(HandlerType);
end;

procedure TAppContainer.AddFactory(
  const ATypeInfo: PTypeInfo;
  const AFactory: TDependencyFactory;
  const ALifetime: TDependencyLifetime
);
begin
  if not Assigned(AFactory) then
    raise EMissingDependencyException.Create('Dependency factory is required.');

  case ALifetime of
    dlSingleton:
      AddDescriptor(TSingletonDependencyDescriptor.Create(ATypeInfo, nil, AFactory));

    dlTransient:
      AddDescriptor(TTransientDependencyDescriptor.Create(ATypeInfo, nil, AFactory));

    dlScoped:
      AddDescriptor(TScopedDependencyDescriptor.Create(ATypeInfo, nil, AFactory));
  end;
end;

function TAppContainer.Resolve(const ATypeInfo: PTypeInfo): TObject;
var
  Descriptor: TDependencyDescriptor;
begin
  EnsureOptionsLoaded;

  Descriptor := GetDescriptor(ATypeInfo);

  case Descriptor.GetLifetime of
    dlSingleton:
      begin
        var SingletonDescriptor := TSingletonDependencyDescriptor(Descriptor);

        if SingletonDescriptor.Instance = nil then
          SingletonDescriptor.Instance := CreateInstance(Descriptor, Self);

        Exit(SingletonDescriptor.Instance);
      end;

    dlTransient:
      Exit(CreateInstance(Descriptor, Self));

    dlScoped:
      raise EMissingDependencyException.CreateFmt(
        'Scoped dependency "%s" must be resolved from a request scope.',
        [ATypeInfo.Name]
      );
  end;

  raise EMissingDependencyException.CreateFmt(
    'Unsupported lifetime for dependency "%s".',
    [ATypeInfo.Name]
  );
end;

function TAppContainer.CreateScope: TContainerScope;
begin
  Result := TContainerScope.Create(Self);
end;

end.
