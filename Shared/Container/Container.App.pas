unit Container.App;

interface

uses
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  Container.Port,
  Container.ServiceDescriptor;

type
  TAppContainer = class(TInterfacedObject, IContainer)
  private
    FDescriptors: TObjectDictionary<PTypeInfo, TServiceDescriptor>;

    procedure AddDescriptor(const ADescriptor: TServiceDescriptor);
    function FindConstructor(const AImplementationType: TClass): TRttiMethod;
    function ResolveConstructorParameter(const AParameter: TRttiParameter; const AResolver: IContainer): TValue;
  public
    constructor Create;
    destructor Destroy; override;

    function CreateInstance(const ADescriptor: TServiceDescriptor; const AResolver: IContainer): TObject;
    function GetDescriptor(const ATypeInfo: PTypeInfo): TServiceDescriptor;

    procedure RegisterInstance(const ATypeInfo: PTypeInfo; const AInstance: TObject);

    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass); overload;
    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject); overload;
    procedure AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
    procedure AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
    procedure AddFactory(
      const ATypeInfo: PTypeInfo;
      const AFactory: TServiceFactory;
      const ALifetime: TServiceLifetime
    );

    function Resolve(const ATypeInfo: PTypeInfo): TObject;
    function CreateScope: IContainer;
  end;

implementation

uses
  System.SysUtils,
  AppExceptions,
  Container.Scope;

constructor TAppContainer.Create;
begin
  inherited Create;
  FDescriptors := TObjectDictionary<PTypeInfo, TServiceDescriptor>.Create([doOwnsValues]);
end;

destructor TAppContainer.Destroy;
begin
  FDescriptors.Free;
  inherited;
end;

procedure TAppContainer.AddDescriptor(const ADescriptor: TServiceDescriptor);
begin
  if ADescriptor.ServiceType = nil then
    raise EMissingDependencyException.Create('Service type is required.');

  FDescriptors.AddOrSetValue(ADescriptor.ServiceType, ADescriptor);
end;

function TAppContainer.GetDescriptor(const ATypeInfo: PTypeInfo): TServiceDescriptor;
begin
  if ATypeInfo = nil then
    raise EMissingDependencyException.Create('Service type is required.');

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

function TAppContainer.ResolveConstructorParameter(const AParameter: TRttiParameter; const AResolver: IContainer): TValue;
var
  ParameterType: TRttiType;
  ResolvedObject: TObject;
  ResolvedInterface: IInterface;
begin
  if AResolver = nil then
    raise EMissingDependencyException.Create('Resolver is required.');

  ParameterType := AParameter.ParamType;

  if ParameterType = nil then
    raise EMissingDependencyException.CreateFmt(
      'Constructor parameter "%s" does not have RTTI type information.',
      [AParameter.Name]
    );

  ResolvedObject := AResolver.Resolve(ParameterType.Handle);

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
            'Resolved service for constructor parameter "%s" does not implement "%s".',
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

function TAppContainer.CreateInstance(const ADescriptor: TServiceDescriptor; const AResolver: IContainer): TObject;
var
  ConstructorMethod: TRttiMethod;
  Parameters: TArray<TRttiParameter>;
  Arguments: TArray<TValue>;
begin
  if Assigned(ADescriptor.Factory) then
    Exit(ADescriptor.Factory(AResolver));

  if ADescriptor.ImplementationType = nil then
    raise EMissingDependencyException.CreateFmt(
      'Type "%s" does not have an implementation type or factory.',
      [ADescriptor.ServiceType.Name]
    );

  ConstructorMethod := FindConstructor(ADescriptor.ImplementationType);

  if ConstructorMethod = nil then
    Exit(ADescriptor.ImplementationType.Create);

  Parameters := ConstructorMethod.GetParameters;
  SetLength(Arguments, Length(Parameters));

  for var Index := 0 to High(Parameters) do
    Arguments[Index] := ResolveConstructorParameter(Parameters[Index], AResolver);

  Result := ConstructorMethod.Invoke(ADescriptor.ImplementationType, Arguments).AsObject;
end;

procedure TAppContainer.RegisterInstance(const ATypeInfo: PTypeInfo; const AInstance: TObject);
begin
  AddSingleton(ATypeInfo, AInstance);
end;

procedure TAppContainer.AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TServiceDescriptor.Create(ATypeInfo, AImplementationType, nil, slSingleton));
end;

procedure TAppContainer.AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject);
var
  Descriptor: TServiceDescriptor;
begin
  if AInstance = nil then
    raise EMissingDependencyException.Create('Singleton instance is required.');

  Descriptor := TServiceDescriptor.Create(ATypeInfo, AInstance.ClassType, nil, slSingleton);
  Descriptor.Instance := AInstance;
  Descriptor.OwnsInstance := True;

  AddDescriptor(Descriptor);
end;

procedure TAppContainer.AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TServiceDescriptor.Create(ATypeInfo, AImplementationType, nil, slTransient));
end;

procedure TAppContainer.AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  if AImplementationType = nil then
    raise EMissingDependencyException.Create('Implementation type is required.');

  AddDescriptor(TServiceDescriptor.Create(ATypeInfo, AImplementationType, nil, slScoped));
end;

procedure TAppContainer.AddFactory(
  const ATypeInfo: PTypeInfo;
  const AFactory: TServiceFactory;
  const ALifetime: TServiceLifetime
);
begin
  if not Assigned(AFactory) then
    raise EMissingDependencyException.Create('Service factory is required.');

  AddDescriptor(TServiceDescriptor.Create(ATypeInfo, nil, AFactory, ALifetime));
end;

function TAppContainer.Resolve(const ATypeInfo: PTypeInfo): TObject;
var
  Descriptor: TServiceDescriptor;
begin
  Descriptor := GetDescriptor(ATypeInfo);

  case Descriptor.Lifetime of
    slSingleton:
      begin
        if Descriptor.Instance = nil then
          Descriptor.Instance := CreateInstance(Descriptor, Self as IContainer);

        Exit(Descriptor.Instance);
      end;

    slTransient:
      Exit(CreateInstance(Descriptor, Self as IContainer));

    slScoped:
      raise EMissingDependencyException.CreateFmt(
        'Scoped service "%s" must be resolved from a request scope.',
        [ATypeInfo.Name]
      );
  end;

  raise EMissingDependencyException.CreateFmt(
    'Unsupported lifetime for service "%s".',
    [ATypeInfo.Name]
  );
end;

function TAppContainer.CreateScope: IContainer;
begin
  Result := TContainerScope.Create(Self);
end;

end.
