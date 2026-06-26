unit Container.Scope;

interface

uses
  System.TypInfo,
  System.Generics.Collections,
  Container.App,
  Container.Port;

type
  TContainerScope = class(TInterfacedObject, IContainer)
  private
    FRoot: TAppContainer;
    FScopedInstances: TDictionary<PTypeInfo, TObject>;
    FTransientInstances: TObjectList<TObject>;
  public
    constructor Create(const ARoot: TAppContainer);
    destructor Destroy; override;

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
  AppExceptions,
  Container.ServiceDescriptor;

constructor TContainerScope.Create(const ARoot: TAppContainer);
begin
  inherited Create;

  if ARoot = nil then
    raise EMissingDependencyException.Create('Root container is required.');

  FRoot := ARoot;
  FScopedInstances := TDictionary<PTypeInfo, TObject>.Create;
  FTransientInstances := TObjectList<TObject>.Create(True);
end;

destructor TContainerScope.Destroy;
begin
  FTransientInstances.Free;

  for var Instance in FScopedInstances.Values do
    Instance.Free;

  FScopedInstances.Free;

  inherited;
end;

procedure TContainerScope.AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  FRoot.AddSingleton(ATypeInfo, AImplementationType);
end;

procedure TContainerScope.AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject);
begin
  FRoot.AddSingleton(ATypeInfo, AInstance);
end;

procedure TContainerScope.AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  FRoot.AddTransient(ATypeInfo, AImplementationType);
end;

procedure TContainerScope.AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
begin
  FRoot.AddScoped(ATypeInfo, AImplementationType);
end;

procedure TContainerScope.AddFactory(
  const ATypeInfo: PTypeInfo;
  const AFactory: TServiceFactory;
  const ALifetime: TServiceLifetime
);
begin
  FRoot.AddFactory(ATypeInfo, AFactory, ALifetime);
end;

function TContainerScope.Resolve(const ATypeInfo: PTypeInfo): TObject;
var
  Descriptor: TServiceDescriptor;
begin
  Descriptor := FRoot.GetDescriptor(ATypeInfo);

  case Descriptor.Lifetime of
    slSingleton:
      Exit(FRoot.Resolve(ATypeInfo));

    slTransient:
      begin
        Result := FRoot.CreateInstance(Descriptor, Self as IContainer);
        FTransientInstances.Add(Result);
        Exit;
      end;

    slScoped:
      begin
        if not FScopedInstances.TryGetValue(ATypeInfo, Result) then
        begin
          Result := FRoot.CreateInstance(Descriptor, Self as IContainer);
          FScopedInstances.Add(ATypeInfo, Result);
        end;

        Exit;
      end;
  end;

  raise EMissingDependencyException.CreateFmt(
    'Unsupported lifetime for service "%s".',
    [ATypeInfo.Name]
  );
end;

function TContainerScope.CreateScope: IContainer;
begin
  Result := TContainerScope.Create(FRoot);
end;

end.
