unit Options.Registry;

interface

uses
  System.TypInfo,
  System.JSON,
  System.Generics.Collections,
  Options.Port;

type
  TOptionsValueLoader = reference to function: TJSONObject;
  TOptionsDescriptorRegistrar = reference to procedure(const ATypeInfo: PTypeInfo; const AInstance: TObject);
  TOptionsSectionMaterializer = reference to procedure;

  TOptionsRegistry = class
  private
    FSectionMaterializers: TList<TOptionsSectionMaterializer>;
    FInstances: TObjectDictionary<PTypeInfo, TObject>;
    FRootLoader: TOptionsValueLoader;
    FRootValue: TJSONObject;
    FLoaded: Boolean;
    FDescriptorRegistrar: TOptionsDescriptorRegistrar;

    function Extract<TOptions: class, constructor>(const ARootOptions: TJSONObject): TOptions;
    procedure RegisterOptionsInstance(const ATypeInfo: PTypeInfo; const AOptionsTypeInfo: PTypeInfo; const AInstance: TObject);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetRootLoader(const ALoader: TOptionsValueLoader; const ADescriptorRegistrar: TOptionsDescriptorRegistrar);
    procedure Add<TOptions: class, constructor>;
    procedure EnsureLoaded;

    function GetGlobal: TJSONObject;
    function Get<TOptions: class, constructor>: TOptions;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  AppExceptions,
  Json.Helpers;

constructor TOptionsRegistry.Create;
begin
  inherited Create;
  FSectionMaterializers := TList<TOptionsSectionMaterializer>.Create;
  FInstances := TObjectDictionary<PTypeInfo, TObject>.Create([doOwnsValues]);
  FLoaded := False;
end;

destructor TOptionsRegistry.Destroy;
begin
  FInstances.Free;
  FSectionMaterializers.Free;
  inherited;
end;

function TOptionsRegistry.Extract<TOptions>(const ARootOptions: TJSONObject): TOptions;
var
  SectionName: string;
  SectionJson: TJSONValue;
  SectionProbe: TOptions;
  OptionsSection: IOptionsSection;
  OptionsTypeName: string;
begin
  if ARootOptions = nil then
    raise EMissingDependencyException.Create('Root options must be a JSON object.');

  OptionsTypeName := TRttiContext.Create.GetType(TypeInfo(TOptions)).Name;

  SectionProbe := TOptions.Create;

  if not Supports(SectionProbe, IOptionsSection, OptionsSection) then
  begin
    SectionProbe.Free;
    raise EMissingDependencyException.CreateFmt(
      'Options class "%s" must implement IOptionsSection.',
      [OptionsTypeName]
    );
  end;

  SectionName := OptionsSection.SectionName.Trim;
  OptionsSection := nil;

  if SectionName.IsEmpty then
    raise EMissingDependencyException.CreateFmt(
      'Options class "%s" returned an empty section name.',
      [OptionsTypeName]
    );

  SectionJson := ARootOptions.GetValue(SectionName);

  if SectionJson = nil then
    raise EMissingDependencyException.CreateFmt(
      'Options section "%s" was not found in root options JSON.',
      [SectionName]
    );

  if not (SectionJson is TJSONObject) then
    raise EMissingDependencyException.CreateFmt(
      'Options section "%s" must be a JSON object.',
      [SectionName]
    );

  Result := TJsonHelpers.ToObject<TOptions>(SectionJson);
end;

procedure TOptionsRegistry.RegisterOptionsInstance(
  const ATypeInfo: PTypeInfo;
  const AOptionsTypeInfo: PTypeInfo;
  const AInstance: TObject
);
begin
  if AInstance = nil then
    raise EMissingDependencyException.Create('Options instance is required.');

  FInstances.AddOrSetValue(AOptionsTypeInfo, AInstance);

  if Assigned(FDescriptorRegistrar) then
    FDescriptorRegistrar(ATypeInfo, AInstance);
end;

procedure TOptionsRegistry.SetRootLoader(
  const ALoader: TOptionsValueLoader;
  const ADescriptorRegistrar: TOptionsDescriptorRegistrar
);
begin
  if not Assigned(ALoader) then
    raise EMissingDependencyException.Create('Options loader is required.');

  FRootLoader := ALoader;
  FDescriptorRegistrar := ADescriptorRegistrar;
  FLoaded := False;

  EnsureLoaded;
end;

procedure TOptionsRegistry.Add<TOptions>;
var
  Materializer: TOptionsSectionMaterializer;
  OptionsInstance: TOptions<TOptions>;
begin
  Materializer :=
    procedure
    begin
      OptionsInstance := TOptions<TOptions>.Create(Extract<TOptions>(FRootValue));
      RegisterOptionsInstance(TypeInfo(IOptions<TOptions>), TypeInfo(TOptions), OptionsInstance);
    end;

  FSectionMaterializers.Add(Materializer);

  if FLoaded then
    Materializer();
end;

procedure TOptionsRegistry.EnsureLoaded;
var
  OptionsInstance: TOptions<TJSONObject>;
begin
  if FLoaded then
    Exit;

  if not Assigned(FRootLoader) then
    Exit;

  FRootValue := FRootLoader();

  if FRootValue = nil then
    raise EMissingDependencyException.Create('Root options loader must return a JSON object.');

  OptionsInstance := TOptions<TJSONObject>.Create(FRootValue);
  RegisterOptionsInstance(TypeInfo(IOptions<TJSONObject>), TypeInfo(TJSONObject), OptionsInstance);

  for var Materializer in FSectionMaterializers do
    Materializer();

  FLoaded := True;
end;

function TOptionsRegistry.GetGlobal: TJSONObject;
begin
  EnsureLoaded;
  Result := FRootValue;
end;

function TOptionsRegistry.Get<TOptions>: TOptions;
begin
  EnsureLoaded;
  Result := Extract<TOptions>(FRootValue);
end;

end.
