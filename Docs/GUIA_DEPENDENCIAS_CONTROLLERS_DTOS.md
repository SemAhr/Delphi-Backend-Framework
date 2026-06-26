# Guía de dependencias, controllers y DTOs

Esta guía describe cómo declarar dependencias, controllers y DTOs en `BackendFramework` usando el contenedor `TAppContainer`, el sistema de rutas por atributos y el binder de DTOs.

## 1. Conceptos principales

El framework separa estas responsabilidades:

- **Rutas:** se descubren al iniciar la aplicación leyendo atributos RTTI sobre clases de controllers.
- **Controllers:** se resuelven desde el contenedor cuando entra una request.
- **Dependencias:** se registran en `TAppContainer` con un ciclo de vida.
- **DTOs:** implementan `IDto` y se usan para entrada/salida JSON.

La unidad principal del contenedor es:

```pas
Container.App
```

El contrato público está en:

```pas
Container.Port
```

---

## 2. Ciclos de vida disponibles

El contenedor soporta tres lifetimes:

```pas
TServiceLifetime = (
  slSingleton,
  slTransient,
  slScoped
);
```

| Lifetime | Comportamiento | Uso recomendado |
|---|---|---|
| `slSingleton` | Una instancia para toda la app. Se crea lazy en el primer `Resolve`. | Logger, configuración, servicios stateless globales. |
| `slTransient` | Nueva instancia cada vez que se resuelve. | Controllers, DTO helpers, servicios livianos. |
| `slScoped` | Una instancia por request/scope. | Repositories, UnitOfWork, servicios con estado de request. |

---

## 3. Declarar dependencias

### 3.1. Definir un puerto/interfaz

Ejemplo:

```pas
unit Auth.Service.Port;

interface

type
  IAuthService = interface
    ['{D3F16087-879E-4F7F-9B14-C7D95EA3E781}']
    function Login(const Email, Password: string): string;
  end;

implementation

end.
```

### 3.2. Implementar el servicio

```pas
unit Auth.Service;

interface

uses
  Auth.Service.Port;

type
  TAuthService = class(TInterfacedObject, IAuthService)
  public
    function Login(const Email, Password: string): string;
  end;

implementation

function TAuthService.Login(const Email, Password: string): string;
begin
  Result := 'jwt-token';
end;

end.
```

### 3.3. Registrar la dependencia

En el `.dpr`, después de crear el contenedor:

```pas
uses
  Container.App,
  Auth.Service.Port,
  Auth.Service;

var
  Container: TAppContainer;
begin
  Container := TAppContainer.Create;
  try
    Container.AddScoped(TypeInfo(IAuthService), TAuthService);
  finally
    Container.Free;
  end;
end.
```

---

## 4. Formas de registrar dependencias

### 4.1. Singleton lazy por tipo

```pas
Container.AddSingleton(TypeInfo(ILogger), TConsoleLogger);
```

La instancia se crea hasta la primera vez que se resuelve.

### 4.2. Singleton por instancia

```pas
Container.AddSingleton(TypeInfo(ILogger), TConsoleLogger.Create);
```

La instancia ya existe al registrarla. El contenedor toma ownership y la libera al destruirse.

### 4.3. Transient

```pas
Container.AddTransient(TypeInfo(TAuthController), TAuthController);
```

Cada `Resolve` crea una nueva instancia.

### 4.4. Scoped

```pas
Container.AddScoped(TypeInfo(IAuthService), TAuthService);
```

Cada request obtiene una instancia propia dentro de su scope.

### 4.5. Factory

Usa factory cuando el constructor necesita valores primitivos o lógica custom.

```pas
Container.AddFactory(
  TypeInfo(IAuthService),
  function(const C: IContainer): TObject
  begin
    Result := TAuthService.Create;
  end,
  slScoped
);
```

Ejemplo con configuración manual:

```pas
Container.AddFactory(
  TypeInfo(ILogger),
  function(const C: IContainer): TObject
  begin
    Result := TConsoleLogger.Create('debug');
  end,
  slSingleton
);
```

---

## 5. Constructor injection

El contenedor soporta constructor injection automático para parámetros de tipo clase o interfaz.

Ejemplo:

```pas
type
  TAuthController = class(TInterfacedObject, IController)
  private
    FAuthService: IAuthService;
  public
    constructor Create(const AAuthService: IAuthService);
  end;
```

Implementación:

```pas
constructor TAuthController.Create(const AAuthService: IAuthService);
begin
  inherited Create;
  FAuthService := AAuthService;
end;
```

Registro:

```pas
Container.AddScoped(TypeInfo(IAuthService), TAuthService);
Container.AddTransient(TypeInfo(TAuthController), TAuthController);
```

Cuando el framework resuelva `TAuthController`, el contenedor resolverá automáticamente `IAuthService`.

### Restricciones actuales

Constructor injection soporta:

```pas
constructor Create(const AService: IAuthService);
constructor Create(const ARepository: TUserRepository);
```

No soporta directamente primitivos:

```pas
constructor Create(const AConnectionString: string);
constructor Create(const APort: Integer);
```

Para esos casos usa `AddFactory`.

---

## 6. Declarar controllers

Todo controller debe implementar `IController`:

```pas
uses
  Http.Controller.Port;

type
  TAuthController = class(TInterfacedObject, IController)
  end;
```

Además, debe usar atributos HTTP para declarar rutas.

### 6.1. Controller básico

```pas
unit Auth.Controller;

interface

uses
  Http.Controller.Port,
  Http.Attributes,
  Http.Parameter.Attributes,
  Auth.Service.Port,
  Auth.Login.Dto,
  Auth.Token.Dto;

type
  [Route('/auth')]
  TAuthController = class(TInterfacedObject, IController)
  private
    FAuthService: IAuthService;
  public
    constructor Create(const AAuthService: IAuthService);

    [Post('/login')]
    [StatusCode(200)]
    function Login([FromBody] const Request: TLoginRequestDto): TTokenDto;
  end;

implementation

constructor TAuthController.Create(const AAuthService: IAuthService);
begin
  inherited Create;
  FAuthService := AAuthService;
end;

function TAuthController.Login(const Request: TLoginRequestDto): TTokenDto;
begin
  Result := TTokenDto.Create;
  Result.Token := FAuthService.Login(Request.Email, Request.Password);
end;

end.
```

### 6.2. Atributos disponibles para rutas

```pas
[Route('/base')]
[Get('/path')]
[Post('/path')]
[Put('/path')]
[Patch('/path')]
[Delete('/path')]
[StatusCode(201)]
```

Ejemplo:

```pas
[Route('/users')]
TUsersController = class(TInterfacedObject, IController)
public
  [Get('/:id')]
  function GetById([FromRoute('id')] const Id: Integer): TUserDto;

  [Post]
  [StatusCode(201)]
  function Create([FromBody] const Request: TCreateUserDto): TUserDto;
end;
```

### 6.3. Atributos disponibles para parámetros

```pas
[FromContext]
[FromRoute('id')]
[FromQuery('q')]
[FromHeader('authorization')]
[FromBody]
```

Ejemplo:

```pas
function Search(
  [FromQuery('q')] const Query: string;
  [FromHeader('authorization')] const Authorization: string
): TSearchResultDto;
```

---

## 7. Registrar controllers

Los controllers deben registrarse en el contenedor, normalmente como `transient`:

```pas
Container.AddTransient(TypeInfo(TAuthController), TAuthController);
```

Luego deben pasarse al scanner para descubrir rutas:

```pas
Routes := Scanner.Execute([
  TAuthController
]);
```

Importante:

- El scanner usa la clase para descubrir rutas.
- No necesita una instancia del controller.
- El controller se crea cuando entra la request.

---

## 8. Declarar DTOs

Todo DTO debe implementar `IDto`:

```pas
uses
  Dto.Port;

type
  TLoginRequestDto = class(TInterfacedObject, IDto)
  end;
```

### 8.1. DTO de entrada

```pas
unit Auth.Login.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TLoginRequestDto = class(TInterfacedObject, IDto)
  private
    FEmail: string;
    FPassword: string;
  public
    [Required]
    [JsonName('email')]
    property Email: string read FEmail write FEmail;

    [Required]
    [JsonName('password')]
    [Length(8, 128)]
    property Password: string read FPassword write FPassword;
  end;

implementation

end.
```

### 8.2. DTO de salida

```pas
unit Auth.Token.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TTokenDto = class(TInterfacedObject, IDto)
  private
    FToken: string;
  public
    [JsonName('token')]
    property Token: string read FToken write FToken;
  end;

implementation

end.
```

---

## 9. Atributos disponibles para DTOs

```pas
[JsonName('field')]
[Required]
[IsDate]
[IsDateTime]
[IsNumberString]
[Length(10)]
[Length(3, 50)]
[Min(1)]
[Max(100)]
[MinItems(1)]
[MaxItems(10)]
[IsIn(['active', 'inactive'])]
```

Ejemplo:

```pas
type
  TCreateUserDto = class(TInterfacedObject, IDto)
  private
    FName: string;
    FAge: Integer;
    FRoles: TArray<string>;
  public
    [Required]
    [JsonName('name')]
    [Length(3, 80)]
    property Name: string read FName write FName;

    [JsonName('age')]
    [Min(18)]
    [Max(120)]
    property Age: Integer read FAge write FAge;

    [JsonName('roles')]
    [MinItems(1)]
    property Roles: TArray<string> read FRoles write FRoles;
  end;
```

---

## 10. Ejemplo completo de arranque en `.dpr`

Ejemplo conceptual:

```pas
uses
  System.SysUtils,
  System.Generics.Collections,
  Container.App,
  Container.Port,
  Http.ControllerScanner,
  Http.RouteDescriptor,
  Http.Http.Composition,
  Http.Http.Server,
  Auth.Controller,
  Auth.Service.Port,
  Auth.Service;

var
  Container: TAppContainer;
  Scanner: TControllerScanner;
  Routes: TObjectList<TRouteDescriptor>;
  Server: THttpServer;
begin
  Container := TAppContainer.Create;
  Scanner := TControllerScanner.Create;
  Routes := nil;
  Server := nil;

  try
    Container.AddScoped(TypeInfo(IAuthService), TAuthService);
    Container.AddTransient(TypeInfo(TAuthController), TAuthController);

    Routes := Scanner.Execute([
      TAuthController
    ]);

    Server := THttpComposition.CreateDefaultServer(
      8080,
      Routes,
      Container
    );

    Server.Start;
    Writeln('Server started on http://localhost:8080');
    Readln;
  finally
    Server.Free;
    Scanner.Free;
    Container.Free;
  end;
end.
```

---

## 11. Recomendaciones

### Controllers

Registrar como transient:

```pas
Container.AddTransient(TypeInfo(TAuthController), TAuthController);
```

Motivo: evitar compartir estado entre requests.

### Servicios stateless

Pueden ser singleton:

```pas
Container.AddSingleton(TypeInfo(ILogger), TConsoleLogger);
```

### Servicios de request o base de datos

Usar scoped:

```pas
Container.AddScoped(TypeInfo(IUserRepository), TUserRepository);
Container.AddScoped(TypeInfo(IUnitOfWork), TUnitOfWork);
```

### Valores primitivos o configuración

Usar factory:

```pas
Container.AddFactory(
  TypeInfo(IJwtService),
  function(const C: IContainer): TObject
  begin
    Result := TJwtService.Create('secret-key');
  end,
  slSingleton
);
```

---

## 12. Checklist rápido

Para agregar un endpoint nuevo:

1. Crear DTOs de entrada/salida implementando `IDto`.
2. Crear el controller implementando `IController`.
3. Agregar `[Route]` al controller.
4. Agregar `[Get]`, `[Post]`, etc. al método.
5. Registrar dependencias del controller.
6. Registrar el controller como transient.
7. Agregar el controller al `Scanner.Execute([...])`.

Ejemplo mínimo:

```pas
Container.AddScoped(TypeInfo(IMyService), TMyService);
Container.AddTransient(TypeInfo(TMyController), TMyController);

Routes := Scanner.Execute([
  TMyController
]);
```
