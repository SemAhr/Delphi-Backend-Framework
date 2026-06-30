# Dependency Container

`TAppContainer` is the application composition root. It owns dependency descriptors, HTTP framework component registries, and typed options registration.

Unit:

```text
Shared/Container/Container.App.pas
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

The container finds the public `Create` constructor with the largest parameter list and resolves constructor parameters from registered dependencies.

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

## Request scopes

`TContainerScope` stores scoped instances and tracks transients created during a request.

The router creates a scope per request and passes it through `TContext`.

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

Container.AddOptions<TOptions>('FieldName');
```
