# Dependency Container

`TAppContainer` is the application composition root. It owns dependency descriptors, HTTP framework component registries, and typed options registration.

Unit:

```text
Source/Shared/Container/Container.App.pas
```

Dependency injection attribute unit:

```text
Source/Shared/Dependencies/Dependency.Attributes.pas
```

## Dependency lifetimes

Dependencies are application services registered by contract/port.

### Singleton

One instance is reused for the application lifetime.

```pascal
Container.AddSingleton<IClock, TSystemClock>;
```

### Scoped

One instance is reused within a request scope.

```pascal
Container.AddScoped<IAuthService, TAuthService>;
```

### Transient

A new instance is created every time the dependency is resolved.

```pascal
Container.AddTransient<IEmailSender, TSmtpEmailSender>;
```

### Factory

Use factories when construction needs custom logic.

```pascal
Container.AddFactory(
  TypeInfo(IMyService),
  function(const Resolve: TDependencyResolver): TObject
  begin
    Result := TMyService.Create;
  end,
  dlSingleton
);
```

## Constructor injection

The container creates dependencies and framework components through public `Create` constructors.

Constructor parameters are resolved from registered dependencies by RTTI. Supported injectable parameter kinds are:

- class types;
- interface types, including closed generic interfaces such as `IOptions<TLoggerOptions>`.

Example:

```pascal
type
  TJwtService = class(TInterfacedObject, IJwtService)
  private
    FOptions: IOptions<TJwtOptions>;
  public
    constructor Create(const AOptions: IOptions<TJwtOptions>);
  end;
```

## Selecting a constructor with `[Inject]`

When a class has multiple public `Create` constructors, mark the constructor intended for dependency injection with `[Inject]`.

Unit:

```pascal
uses
  Dependency.Attributes;
```

Example:

```pascal
uses
  Dependency.Attributes,
  Options.Port;

type
  TJwtService = class(TInterfacedObject, IJwtService)
  public
    constructor Create; overload;

    [Inject]
    constructor Create(const AOptions: IOptions<TJwtOptions>); overload;
  end;
```

The attribute is declared as:

```pascal
InjectAttribute = class(TCustomAttribute);
```

### Constructor selection rules

`TAppContainer` uses these rules:

1. It scans public constructors named `Create` declared on the concrete implementation type.
2. If exactly one constructor is marked with `[Inject]`, that constructor is used.
3. If more than one constructor is marked with `[Inject]`, the container raises an error.
4. If none is marked and there is exactly one public `Create` constructor, that constructor is used.
5. If none is marked and there are multiple public `Create` constructors, the container raises an error asking you to mark one with `[Inject]`.
6. If no public `Create` constructor is discovered by RTTI, the component falls back to `AImplementationType.Create`.

This avoids guessing based on the constructor with the largest parameter list.

## Resolving options through constructor injection

Options are injected as `IOptions<TOptions>`.

```pascal
constructor TLogger.Create(const AOptions: IOptions<TLoggerOptions>);
begin
  inherited Create;
  FOptions := AOptions.Value;
end;
```

The options registry stores a correctly typed value for each closed generic interface, for example:

```pascal
IOptions<TLoggerOptions>
```

This allows RTTI constructor invocation to receive the exact interface type expected by the constructor.

## Request scopes

`TContainerScope` stores scoped instances and tracks transients created during a request.

The router creates a scope per request and passes it through `TContext`.

Singleton dependencies are resolved from the root container. Scoped dependencies must be resolved from a request scope.

## HTTP framework components

These are not dependency registrations:

```pascal
Container.AddController(TUsersController);
Container.Use(TExceptionMiddleware);
Container.AddAttributeHandler(TRequireRoleHandler);
```

They are concrete framework components. The framework creates them with constructor injection using the current request scope.

## Public API summary

```pascal
Container.AddSingleton<IDependency, TImplementation>;
Container.AddScoped<IDependency, TImplementation>;
Container.AddTransient<IDependency, TImplementation>;
Container.AddFactory(TypeInfo(IDependency), Factory, dlScoped);

Container.AddController(TControllerClass);
Container.AddControllers([TOneController, TAnotherController]);

Container.Use(TMiddlewareClass);
Container.Use([TFirstMiddleware, TSecondMiddleware]);

Container.AddAttributeHandler(THandlerClass);
Container.AddAttributeHandlers([TOneHandler, TAnotherHandler]);

Container.AddOptions<TOptions>;
```

## Common errors

### Multiple constructors without `[Inject]`

If a type has more than one public `Create` constructor, mark the injectable one:

```pascal
[Inject]
constructor Create(const ARepository: IUserRepository; const ALogger: ILogger);
```

### Missing dependency registration

Every constructor parameter must be registered or provided by framework infrastructure.

For example, this constructor requires `ILogger` to be registered:

```pascal
constructor Create(const ALogger: ILogger);
```

Registration:

```pascal
Container.AddSingleton<ILogger, TLogger>;
```

### Missing options registration

A constructor that asks for:

```pascal
IOptions<TLoggerOptions>
```

requires:

```pascal
Container.AddOptions<TLoggerOptions>;
```

unless the framework registers that options type by default.
