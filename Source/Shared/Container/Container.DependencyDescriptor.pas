unit Container.DependencyDescriptor;

interface

uses
  System.TypInfo;

type
  TDependencyLifetime = (
    dlSingleton,
    dlTransient,
    dlScoped
  );

  TDependencyResolver = reference to function(const ATypeInfo: PTypeInfo): TObject;

  TDependencyFactory = reference to function(const AResolve: TDependencyResolver): TObject;

  /// <summary>
  /// Base descriptor for a dependency registration.
  /// </summary>
  /// <remarks>
  /// The base descriptor only stores metadata that applies to every lifetime. Lifetime-specific
  /// state, such as a cached singleton instance, belongs to specialized descriptor classes.
  /// </remarks>
  TDependencyDescriptor = class abstract
  private
    FDependencyType: PTypeInfo;
    FImplementationType: TClass;
    FFactory: TDependencyFactory;
  public
    /// <summary>
    /// Creates the common metadata for a dependency registration.
    /// </summary>
    /// <param name="ADependencyType">
    /// The type requested by consumers and used as the container lookup key.
    /// </param>
    /// <param name="AImplementationType">
    /// Concrete class to instantiate when no custom factory is provided.
    /// </param>
    /// <param name="AFactory">
    /// Optional custom creation function. When assigned, the container uses it instead of creating
    /// ImplementationType directly.
    /// </param>
    constructor Create(
      const ADependencyType: PTypeInfo;
      const AImplementationType: TClass;
      const AFactory: TDependencyFactory
    );

    /// <summary>
    /// Returns the lifecycle represented by the concrete descriptor type.
    /// </summary>
    function GetLifetime: TDependencyLifetime; virtual; abstract;

    /// <summary>
    /// Type requested by consumers and used as the lookup key in the container.
    /// </summary>
    property DependencyType: PTypeInfo read FDependencyType;

    /// <summary>
    /// Concrete class to instantiate when the dependency is resolved without a custom factory.
    /// </summary>
    property ImplementationType: TClass read FImplementationType;

    /// <summary>
    /// Optional custom creation function used to build the dependency instance.
    /// </summary>
    property Factory: TDependencyFactory read FFactory;
  end;

  /// <summary>
  /// Descriptor for dependencies that live for the whole application lifetime.
  /// </summary>
  /// <remarks>
  /// Singleton-specific state is stored here because only singleton dependencies cache their
  /// instance inside the root container.
  /// </remarks>
  TSingletonDependencyDescriptor = class(TDependencyDescriptor)
  private
    FInstance: TObject;
    FOwnsInstance: Boolean;
  public
    /// <summary>
    /// Creates a singleton descriptor without an already-created instance.
    /// </summary>
    constructor Create(
      const ADependencyType: PTypeInfo;
      const AImplementationType: TClass;
      const AFactory: TDependencyFactory
    );
    destructor Destroy; override;

    /// <summary>
    /// Returns dlSingleton for this descriptor type.
    /// </summary>
    function GetLifetime: TDependencyLifetime; override;

    /// <summary>
    /// Cached singleton instance. It is normally created lazily on the first Resolve call.
    /// </summary>
    property Instance: TObject read FInstance write FInstance;

    /// <summary>
    /// Indicates whether this descriptor owns and should free Instance when destroyed.
    /// </summary>
    property OwnsInstance: Boolean read FOwnsInstance write FOwnsInstance;
  end;

  /// <summary>
  /// Descriptor for dependencies that must be created every time they are resolved.
  /// </summary>
  TTransientDependencyDescriptor = class(TDependencyDescriptor)
  public
    /// <summary>
    /// Returns dlTransient for this descriptor type.
    /// </summary>
    function GetLifetime: TDependencyLifetime; override;
  end;

  /// <summary>
  /// Descriptor for dependencies that are reused within a single request/scope.
  /// </summary>
  /// <remarks>
  /// Scoped instances are intentionally not stored here. They live in TContainerScope because each
  /// request/scope must have its own instance cache.
  /// </remarks>
  TScopedDependencyDescriptor = class(TDependencyDescriptor)
  public
    /// <summary>
    /// Returns dlScoped for this descriptor type.
    /// </summary>
    function GetLifetime: TDependencyLifetime; override;
  end;

implementation

constructor TDependencyDescriptor.Create(
  const ADependencyType: PTypeInfo;
  const AImplementationType: TClass;
  const AFactory: TDependencyFactory
);
begin
  inherited Create;
  FDependencyType := ADependencyType;
  FImplementationType := AImplementationType;
  FFactory := AFactory;
end;

constructor TSingletonDependencyDescriptor.Create(
  const ADependencyType: PTypeInfo;
  const AImplementationType: TClass;
  const AFactory: TDependencyFactory
);
begin
  inherited Create(ADependencyType, AImplementationType, AFactory);
  FOwnsInstance := True;
end;

destructor TSingletonDependencyDescriptor.Destroy;
begin
  if FOwnsInstance then
    FInstance.Free;

  inherited;
end;

function TSingletonDependencyDescriptor.GetLifetime: TDependencyLifetime;
begin
  Result := dlSingleton;
end;

function TTransientDependencyDescriptor.GetLifetime: TDependencyLifetime;
begin
  Result := dlTransient;
end;

function TScopedDependencyDescriptor.GetLifetime: TDependencyLifetime;
begin
  Result := dlScoped;
end;

end.
