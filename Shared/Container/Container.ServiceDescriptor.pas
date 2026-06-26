unit Container.ServiceDescriptor;

interface

uses
  System.TypInfo,
  Container.Port;

type
  TServiceDescriptor = class
  private
    FServiceType: PTypeInfo;
    FImplementationType: TClass;
    FFactory: TServiceFactory;
    FInstance: TObject;
    FLifetime: TServiceLifetime;
    FOwnsInstance: Boolean;
  public
    constructor Create(
      const AServiceType: PTypeInfo;
      const AImplementationType: TClass;
      const AFactory: TServiceFactory;
      const ALifetime: TServiceLifetime
    );
    destructor Destroy; override;

    property ServiceType: PTypeInfo read FServiceType;
    property ImplementationType: TClass read FImplementationType;
    property Factory: TServiceFactory read FFactory;
    property Instance: TObject read FInstance write FInstance;
    property Lifetime: TServiceLifetime read FLifetime;
    property OwnsInstance: Boolean read FOwnsInstance write FOwnsInstance;
  end;

implementation

constructor TServiceDescriptor.Create(
  const AServiceType: PTypeInfo;
  const AImplementationType: TClass;
  const AFactory: TServiceFactory;
  const ALifetime: TServiceLifetime
);
begin
  inherited Create;
  FServiceType := AServiceType;
  FImplementationType := AImplementationType;
  FFactory := AFactory;
  FLifetime := ALifetime;
  FOwnsInstance := True;
end;

destructor TServiceDescriptor.Destroy;
begin
  if FOwnsInstance then
    FInstance.Free;

  inherited;
end;

end.
