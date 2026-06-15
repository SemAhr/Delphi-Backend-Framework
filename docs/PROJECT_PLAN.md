# BackendFramework - Plan de requisitos y arquitectura

## 1. Objetivo del proyecto

`BackendFramework` será un framework backend para Delphi orientado a construir APIs HTTP de forma declarativa, usando controladores, atributos, inyección de dependencias, middlewares, configuración por opciones, logging y serialización JSON automática.

Aunque el proyecto es un framework y no una aplicación de negocio, debe mantener una arquitectura ordenada, extensible y testeable. En particular, se debe respetar la inyección de dependencias y evitar que los componentes principales creen directamente sus dependencias concretas, salvo dentro de puntos de composición claramente definidos.

---

## 2. Principios de diseño

### 2.1. Controller-based

El framework estará basado en controladores.

Un controlador será una clase que implemente el contrato base del framework, por ejemplo:

```pascal
IHttpController = interface
end;
```

Los métodos públicos del controlador podrán exponerse como endpoints HTTP mediante atributos.

Ejemplo conceptual:

```pascal
[Route('/users')]
TUsersController = class(TInterfacedObject, IHttpController)
public
  [Get('/:id')]
  function GetById([FromRoute('id')] const Id: Integer): TUserResponseDto;
end;
```

### 2.2. Declarativo mediante attributes

El framework usará atributos para describir:

- Rutas.
- Métodos HTTP.
- Parámetros de entrada.
- Códigos de respuesta.
- Documentación Swagger/OpenAPI.
- Middlewares aplicables.
- Metadata global, por controlador o por acción.

### 2.3. Inyección de dependencias obligatoria para componentes extensibles

Los componentes internos del framework deben depender de contratos cuando su comportamiento pueda variar.

Ejemplos:

- Router.
- Action invoker.
- Parameter binder.
- Body binder.
- DTO binder.
- Serializer.
- Middleware pipeline.
- Logger.
- Options/configuration provider.
- Exception handler.
- Swagger generator.

La creación de implementaciones concretas debe ocurrir principalmente en el composition root del framework o en el container global de la aplicación.

### 2.4. Framework pragmático, no Clean Architecture estricta

No se busca imponer Clean Architecture a las aplicaciones consumidoras. Sin embargo, el framework sí debe mantener separación de responsabilidades.

La arquitectura debe distinguir entre:

- Contratos públicos.
- Núcleo HTTP.
- Routing.
- Binding.
- Middlewares.
- Serialización.
- Manejo de errores.
- Configuración.
- Logging.
- Infraestructura concreta, por ejemplo Indy.

---

## 3. Requisitos funcionales

## 3.1. Routing basado en controladores

### Requisitos

- Permitir definir rutas mediante atributos en clases y métodos.
- Soportar ruta base por controlador.
- Soportar ruta específica por acción.
- Combinar ruta base + ruta de acción.
- Soportar parámetros de ruta.
- Resolver automáticamente la acción correspondiente según método HTTP y path.

### Métodos HTTP requeridos

- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`

### Attributes esperados

```pascal
[Route('/base-path')]
[Get('/path')]
[Post('/path')]
[Put('/path')]
[Patch('/path')]
[Delete('/path')]
```

### Consideraciones

- La comparación de método HTTP debe ser case-insensitive.
- Las rutas deben normalizarse para evitar inconsistencias por `/` al inicio o al final.
- Los errores de definición de rutas deben detectarse temprano, idealmente al iniciar la aplicación.

---

## 3.2. Attributes para parámetros de entrada

### Requisitos

Permitir controlar desde dónde se obtiene cada parámetro de una acción del controlador.

### Fuentes de parámetros

- Contexto HTTP.
- Route params.
- Query params.
- Headers.
- Body JSON.

### Attributes esperados

```pascal
[FromContext]
[FromRoute('id')]
[FromQuery('page')]
[FromHeader('authorization')]
[FromBody]
```

### Ejemplo conceptual

```pascal
[Get('/:id')]
function GetById(
  [FromRoute('id')] const Id: Integer,
  [FromHeader('authorization')] const Authorization: string
): TUserResponseDto;
```

### Consideraciones

- Debe existir validación clara cuando un parámetro requerido no esté presente.
- Deben existir errores claros cuando no se pueda convertir un valor al tipo esperado.
- El binding de body debe usar JSON exclusivamente.
- El binder debe ser extensible mediante contratos.

---

## 3.3. Content-Type JSON obligatorio para requests entrantes

### Requisito

Para requests con body, el framework solo debe permitir comunicación con:

```http
Content-Type: application/json
```

También debe aceptar variantes válidas como:

```http
application/json; charset=utf-8
```

### Comportamiento esperado

Si el request tiene body y el `Content-Type` no es JSON, se debe retornar un error HTTP apropiado, probablemente:

```http
415 Unsupported Media Type
```

Formato de respuesta:

```json
{
  "error": "Unsupported Media Type",
  "description": "Only application/json content type is supported."
}
```

### Implementación sugerida

Este comportamiento debería implementarse como middleware de entrada global, no dentro de cada controlador.

---

## 3.4. Attributes globales

### Requisito

Permitir definir atributos globales para no tener que repetirlos en cada ruta o controlador.

### Casos de uso

- Middleware global.
- Produces JSON global.
- Consumes JSON global.
- Authorization global futura.
- Tags Swagger globales o por grupo.
- Headers comunes.
- Respuestas comunes.

### Niveles de aplicación

El framework debería soportar metadata en estos niveles:

1. Global.
2. Controller.
3. Action.
4. Parameter.

### Regla de precedencia sugerida

```text
Action > Controller > Global
```

Para parámetros:

```text
Parameter > Action > Controller > Global
```

---

## 3.5. Respuestas JSON automáticas

### Requisito

El framework debe serializar automáticamente las respuestas de las acciones a JSON.

### Casos esperados

Una acción puede retornar:

- `THttpResponse` explícito.
- DTO de salida.
- Objeto simple.
- Array/lista de DTOs.
- Valor primitivo.
- Void/no result.

### Comportamiento esperado

Si la acción retorna un DTO:

```pascal
function GetUser: TUserResponseDto;
```

El framework debe convertirlo automáticamente a:

```json
{
  "id": 1,
  "name": "John"
}
```

### Contratos sugeridos

- `IJsonSerializer`
- `IResponseWriter`
- `IActionResultMapper`

### Consideraciones

- Debe respetar attributes de DTO como `JsonName`.
- Debe permitir definir content type por defecto:

```http
application/json; charset=utf-8
```

- Debe liberar correctamente objetos creados durante binding o serialización cuando aplique.

---

## 3.6. Status code por defecto

### Requisito

El framework debe asignar un status code HTTP por defecto según el tipo de operación o resultado.

### Defaults sugeridos

| Caso | Status code |
|---|---:|
| `GET` exitoso con body | `200 OK` |
| `POST` exitoso con body | `201 Created` |
| `PUT` exitoso | `200 OK` o `204 No Content` |
| `PATCH` exitoso | `200 OK` o `204 No Content` |
| `DELETE` exitoso | `204 No Content` |
| Acción sin retorno | `204 No Content` |
| Ruta no encontrada | `404 Not Found` |
| Error de validación/binding | `400 Bad Request` |
| Content-Type no soportado | `415 Unsupported Media Type` |
| Error no controlado | `500 Internal Server Error` |

### Override por attribute

Debe ser posible sobrescribir el status code por defecto:

```pascal
[StatusCode(202)]
[Post]
function Create(...): TCreateUserResponseDto;
```

---

## 3.7. Manejo global de errores

### Requisito

Debe existir un gestor global de errores que capture excepciones lanzadas en cualquier parte del pipeline:

- Middlewares.
- Binding.
- Validación.
- Controller scanner.
- Action invoker.
- Controladores de aplicación.
- Serialización de respuesta.

### Formato de respuesta requerido

```json
{
  "error": "error-name",
  "description": "error-description"
}
```

O, para múltiples errores:

```json
{
  "error": "error-name",
  "description": [
    "error-description-1",
    "error-description-2"
  ]
}
```

### Requisitos de excepción HTTP

Las excepciones del framework deben permitir asociar:

- Status code HTTP.
- Nombre de error.
- Descripción única o lista de descripciones.
- Excepción interna opcional.

### Ejemplo conceptual

```pascal
raise EBadRequestException.Create('Invalid request body.');
```

Debe producir:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json; charset=utf-8
```

```json
{
  "error": "Bad Request",
  "description": "Invalid request body."
}
```

### Contratos sugeridos

- `IExceptionHandler`
- `IExceptionResponseMapper`
- `IErrorResponseFactory`

### Consideraciones

- El handler global no debería exponer detalles internos en producción.
- Debe ser configurable si se incluyen detalles técnicos.
- Debe integrarse con el logger global.

---

## 3.8. Middlewares de entrada y salida

### Requisito

El framework debe soportar middlewares tanto para entrada como para salida.

### Middlewares de entrada

Se ejecutan antes de invocar el controlador.

Casos de uso:

- Validar `Content-Type`.
- Logging de request.
- Correlation ID.
- Autenticación futura.
- Autorización futura.
- Rate limiting futuro.
- Normalización de headers.

### Middlewares de salida

Se ejecutan después de generar la respuesta, pero antes de enviarla al cliente.

Casos de uso:

- Logging de response.
- Agregar headers globales.
- Transformar respuesta.
- CORS futuro.
- Compression futura.

### Modelo sugerido

Usar un pipeline tipo Minimal API:

```text
Request
  -> Middleware 1
  -> Middleware 2
  -> Routing
  -> Binding
  -> Controller Action
  -> Response Mapping
  -> Outgoing Middleware 2
  -> Outgoing Middleware 1
Response
```

### Contratos sugeridos

```pascal
IHttpMiddleware = interface
  function Invoke(const Context: THttpContext; const Next: THttpNext): THttpResponse;
end;
```

También puede evaluarse separar:

- `IIncomingMiddleware`
- `IOutgoingMiddleware`

Sin embargo, un único pipeline bidireccional puede ser más flexible.

### Definición global y por controller/action

Los middlewares deben poder registrarse:

- Globalmente.
- Por controller mediante attribute.
- Por action mediante attribute.

---

## 3.9. Swagger/OpenAPI automático mediante attributes

### Requisito

Generar documentación automática Swagger/OpenAPI usando metadata declarada con attributes y la información obtenida por RTTI.

### Metadata esperada

- Ruta.
- Método HTTP.
- Parámetros.
- Query params.
- Route params.
- Headers.
- Body schema.
- Response schema.
- Status codes.
- Tags.
- Summary.
- Description.
- Deprecated.
- Produces/Consumes.

### Attributes sugeridos

```pascal
[ApiTag('Users')]
[Summary('Gets a user by id')]
[Description('Returns the user matching the given id.')]
[ProducesResponse(200, TUserResponseDto)]
[ProducesResponse(404, TErrorResponseDto)]
[Consumes('application/json')]
[Produces('application/json')]
```

### Endpoints esperados

El framework debería poder exponer:

```http
GET /swagger.json
GET /swagger
```

### Contratos sugeridos

- `IOpenApiGenerator`
- `ISchemaGenerator`
- `ISwaggerEndpointProvider`

### Consideraciones

- La documentación debe generarse a partir del mismo route registry usado por el router.
- Evitar duplicar metadata entre runtime y documentación.
- Los DTOs deben analizarse por RTTI.
- Los attributes de DTO deben influir en el schema.

---

## 3.10. Options y configuración desde JSON

### Requisito

Agregar gestión de opciones para lectura de configuración desde archivos JSON, siguiendo una idea similar a:

```text
..\atm-api\Source\Config\
```

Actualmente no se pudo revisar esa ruta desde el workspace, por lo que el diseño queda planteado a nivel de framework hasta tener acceso al ejemplo.

### Objetivo

Permitir que las aplicaciones consumidoras configuren opciones fuertemente tipadas desde archivos JSON.

### Ejemplo conceptual de archivo

```json
{
  "Server": {
    "Port": 8080
  },
  "Logging": {
    "Level": "Information"
  },
  "Swagger": {
    "Enabled": true,
    "Route": "/swagger"
  }
}
```

### Ejemplo conceptual de uso

```pascal
App.Services.Configure<TServerOptions>('Server');
App.Services.Configure<TLoggingOptions>('Logging');
```

O:

```pascal
ServerOptions := Options.Get<TServerOptions>;
```

### Contratos sugeridos

- `IConfiguration`
- `IConfigurationProvider`
- `IJsonConfigurationProvider`
- `IOptions<T>`
- `IOptionsMonitor<T>` opcional a futuro

### Requisitos mínimos

- Leer configuración desde JSON.
- Bindear secciones a clases de opciones.
- Registrar opciones en el container.
- Permitir valores por defecto.
- Permitir validación de opciones.

### Requisitos futuros posibles

- Soporte para múltiples archivos:
  - `appsettings.json`
  - `appsettings.Development.json`
  - `appsettings.Production.json`
- Variables de entorno.
- Reload on change.
- Secrets externos.

---

## 3.11. Container global de dependencias

### Requisito

El framework debe proveer un container global para que las aplicaciones declaren sus dependencias, similar conceptualmente a Minimal API.

### Objetivo

Permitir registrar servicios de aplicación y servicios internos del framework.

### Ciclos de vida requeridos

| Lifetime | Descripción |
|---|---|
| `Transient` | Nueva instancia cada vez que se resuelve. |
| `Scoped` | Una instancia por scope/request. |
| `Singleton` | Una única instancia para toda la aplicación. |

### Ejemplo conceptual

```pascal
App.Services.AddTransient<IUserService, TUserService>;
App.Services.AddScoped<IUnitOfWork, TUnitOfWork>;
App.Services.AddSingleton<ILogger, TConsoleLogger>;
```

### Resolución en controladores

El framework debe resolver controladores desde el container.

```pascal
Controller := Container.Resolve(Route.ControllerType.Handle);
```

Pero el container debe saber construir el controller con sus dependencias de constructor.

Ejemplo:

```pascal
TUsersController = class(TInterfacedObject, IHttpController)
private
  FUserService: IUserService;
public
  constructor Create(const AUserService: IUserService);
end;
```

### Scopes por request

Cada request debe crear un scope.

```text
Request starts
  -> Create scope
  -> Resolve controller and scoped dependencies
  -> Execute pipeline
  -> Dispose scope
Request ends
```

### Contratos sugeridos

- `IServiceCollection`
- `IServiceProvider`
- `IServiceScope`
- `IServiceScopeFactory`
- `IContainer` actual puede evolucionar o adaptarse

### Consideraciones

- Los singletons deben ser thread-safe si el servidor maneja requests concurrentes.
- Los scoped services deben liberarse al finalizar el request.
- El container debe detectar dependencias faltantes con mensajes claros.
- Debe evitar dependencias circulares o reportarlas claramente.

---

## 3.12. Logger global

### Requisito

Agregar logger global similar conceptualmente a:

```text
..\atm-api\Source\Common\Logging\
..\atm-api\Source\Infrastructure\Logging\
```

Actualmente no se pudo acceder a esas rutas desde el workspace, por lo que el diseño queda planteado hasta poder comparar el ejemplo.

### Objetivo

Permitir logging global para el framework y para la aplicación consumidora.

### Niveles mínimos

- Trace
- Debug
- Information
- Warning
- Error
- Critical

### Contratos sugeridos

```pascal
ILogger = interface
  procedure Trace(const Message: string);
  procedure Debug(const Message: string);
  procedure Information(const Message: string);
  procedure Warning(const Message: string);
  procedure Error(const Message: string; const Exception: Exception = nil);
  procedure Critical(const Message: string; const Exception: Exception = nil);
end;
```

También puede evaluarse un logger tipado:

```pascal
ILogger<T>
```

si resulta práctico en Delphi.

### Usos internos

- Inicio y parada del servidor.
- Requests entrantes.
- Responses salientes.
- Excepciones no controladas.
- Errores de binding.
- Errores de configuración.
- Registro/resolución de dependencias si se habilita modo debug.

### Implementaciones posibles

- Console logger.
- File logger.
- Null logger.
- Adapter a librerías externas en el futuro.

---

## 4. Arquitectura propuesta del framework

## 4.1. Enfoque general

El framework no impondrá Clean Architecture a las aplicaciones consumidoras, pero internamente debe organizarse en módulos claros y con dependencias hacia contratos.

La arquitectura interna puede verse así:

```text
Application startup
  -> Service collection
  -> Configuration/options
  -> Logging
  -> Controller discovery
  -> Route registry
  -> Middleware pipeline
  -> Server adapter
```

### Regla principal

Los módulos de alto nivel del framework no deben depender directamente de implementaciones concretas cuando exista variabilidad.

Ejemplo correcto:

```text
Http.Server -> IHttpRouter
Http.AttributeRouter -> IControllerActionInvoker
Http.ParameterBinder -> IHttpBodyBinder
Http.JsonBodyBinder -> IDtoBinder
```

Ejemplo a evitar:

```text
Http.JsonBodyBinder -> TDtoBinder.Create dentro del constructor
```

Ese caso ya fue corregido para usar `IDtoBinder`.

---

## 4.2. Estructura actual/propuesta

La estructura base acordada es:

```text
BackendFramework/
  Shared/
    Container/
    Exceptions/
    Rtti/

  Dto/
    Attributes/
    Binding/
    Validation/
      Validators/

  Http/
    Attributes/
    Context/
    Controllers/
    Parameters/
    Routing/
    Http.Core.pas
    Http.Server.pas
    Http.Composition.pas
```

### Evolución sugerida

A medida que crezca el proyecto, podrían agregarse módulos como:

```text
BackendFramework/
  Configuration/
    Configuration.Contract.pas
    JsonConfigurationProvider.pas
    Options.pas

  Logging/
    Logging.Contract.pas
    ConsoleLogger.pas
    NullLogger.pas

  Middleware/
    Middleware.Contract.pas
    Middleware.Pipeline.pas
    JsonContentTypeMiddleware.pas
    ExceptionHandlingMiddleware.pas
    LoggingMiddleware.pas

  Serialization/
    JsonSerializer.Contract.pas
    JsonSerializer.pas

  OpenApi/
    OpenApi.Attributes.pas
    OpenApi.Generator.Contract.pas
    OpenApi.Generator.pas
    OpenApi.SchemaGenerator.pas

  Hosting/
    ApplicationBuilder.pas
    WebApplication.pas
    ServiceCollection.pas
```

---

## 4.3. Capas internas sugeridas

### Shared

Código transversal sin dependencia directa de HTTP:

- Exceptions base.
- Helpers RTTI.
- Contratos de container.
- Tipos comunes.

### Dto

Binding, validación y metadata de DTOs:

- Attributes de DTO.
- Binder JSON -> DTO.
- Validator de propiedades.
- Metadata de serialización.

### Http

Núcleo HTTP del framework:

- Request/response.
- Context.
- Routing.
- Controllers.
- Parameters.
- Server adapter.

### Middleware

Pipeline de entrada/salida.

Puede vivir inicialmente bajo `Http/Middleware`, pero si crece, conviene moverlo a módulo propio:

```text
Middleware/
```

### Configuration

Sistema de configuración y opciones.

Debe quedar desacoplado de HTTP para que pueda usarse por cualquier parte del framework o de la aplicación.

### Logging

Contratos e implementaciones de logging.

Debe ser transversal y resoluble desde el container.

### OpenApi

Generación Swagger/OpenAPI.

Debe consumir metadata del routing y de DTOs, pero no duplicar scanner.

---

## 5. Pipeline HTTP esperado

Flujo conceptual:

```text
Raw HTTP request
  -> Server adapter, por ejemplo Indy
  -> Build THttpRequest
  -> Create request scope
  -> Create THttpContext
  -> Global exception handler
  -> Incoming middleware pipeline
  -> Route matching
  -> Action metadata resolution
  -> Parameter binding
  -> Controller resolution from container
  -> Action invocation
  -> Response mapping / JSON serialization
  -> Outgoing middleware pipeline
  -> Write THttpResponse
  -> Dispose request scope
```

### Observación importante

El exception handler global debe envolver la mayor parte del pipeline para capturar errores en:

- Middlewares.
- Routing.
- Binding.
- Controller resolution.
- Action invocation.
- Serialization.

---

## 6. Application builder sugerido

Para acercarse al estilo Minimal API, se puede diseñar una API de arranque como:

```pascal
var App := TBackendApplication.Create;

App.Configuration
  .AddJsonFile('appsettings.json')
  .AddJsonFile('appsettings.Development.json', True);

App.Services
  .AddLogging
  .AddOptions
  .AddControllers([TUsersController, TProductsController])
  .AddScoped<IUserService, TUserService>
  .AddSingleton<ICache, TMemoryCache>;

App.UseMiddleware<TJsonContentTypeMiddleware>;
App.UseMiddleware<TExceptionHandlingMiddleware>;
App.UseSwagger;

App.Run(8080);
```

Esto no tiene que implementarse todavía, pero sirve como objetivo de diseño.

---

## 7. Contratos importantes pendientes

### Dependency Injection

```text
IServiceCollection
IServiceProvider
IServiceScope
IServiceScopeFactory
IContainer
```

### Middleware

```text
IHttpMiddleware
IMiddlewarePipeline
IIncomingMiddleware opcional
IOutgoingMiddleware opcional
```

### Error handling

```text
IExceptionHandler
IExceptionResponseMapper
IErrorResponseFactory
```

### Serialization

```text
IJsonSerializer
IResponseWriter
IActionResultMapper
```

### Configuration / Options

```text
IConfiguration
IConfigurationProvider
IJsonConfigurationProvider
IOptions<T>
```

### Logging

```text
ILogger
ILoggerFactory opcional
```

### Swagger/OpenAPI

```text
IOpenApiGenerator
ISchemaGenerator
ISwaggerEndpointProvider
```

---

## 8. Prioridades sugeridas de implementación

### Fase 1 - Base sólida de DI y hosting

1. Diseñar `IServiceCollection`, `IServiceProvider`, scopes y lifetimes.
2. Integrar resolución de controladores desde el container.
3. Crear request scope por request.
4. Mantener `Http.Composition` como composition root inicial.

### Fase 2 - Pipeline y errores

1. Diseñar middleware pipeline.
2. Implementar exception handler global.
3. Implementar formato estándar de error.
4. Implementar middleware de `Content-Type: application/json`.

### Fase 3 - Responses y serialización

1. Crear serializador JSON por contrato.
2. Mapear retorno de actions a `THttpResponse`.
3. Definir status codes por defecto.
4. Permitir override con attributes.

### Fase 4 - Configuration, Options y Logging

1. Crear configuración desde JSON.
2. Crear binding de opciones tipadas.
3. Registrar options en el container.
4. Crear logger global.
5. Integrar logger en pipeline y exception handler.

### Fase 5 - Swagger/OpenAPI

1. Definir attributes de documentación.
2. Generar schemas desde DTOs.
3. Generar OpenAPI desde route registry.
4. Exponer `/swagger.json`.
5. Exponer UI `/swagger` si se decide incluirla.

---

## 9. Decisiones abiertas

### 9.1. Un solo middleware o entrada/salida separados

Opciones:

1. Un único `IHttpMiddleware` bidireccional.
2. Separar `IIncomingMiddleware` e `IOutgoingMiddleware`.

Recomendación inicial: usar un único pipeline porque permite envolver entrada y salida naturalmente.

### 9.2. Naming de módulos nuevos

Pendiente decidir si módulos nuevos vivirán bajo `Http/` o en raíz:

```text
Http/Middleware
```

versus:

```text
Middleware
```

Recomendación: si son estrictamente HTTP, usar `Http/Middleware`. Si se vuelven transversales, mover a `Middleware`.

### 9.3. Swagger UI

Pendiente decidir si el framework solo generará `swagger.json` o también servirá Swagger UI embebido.

### 9.4. Container propio vs adapter

Pendiente decidir si:

1. Se implementa un container propio.
2. Se crea una abstracción compatible con containers externos.

Recomendación inicial: implementar container propio mínimo con `Transient`, `Scoped` y `Singleton`, manteniendo contratos para poder adaptar otro container en el futuro.

---

## 10. Conclusión arquitectónica

El proyecto puede mantenerse como framework pragmático sin imponer Clean Architecture estricta. Sin embargo, sí debe aplicar principios importantes:

- Separación clara de responsabilidades.
- Dependencias hacia contratos.
- Composition root explícito.
- DI para componentes extensibles.
- Pipeline HTTP desacoplado.
- Manejo global de errores.
- Configuración y logging transversales.
- Metadata única reutilizable para routing y Swagger.

La estructura actual ya va en esa dirección con módulos `Shared`, `Dto` y `Http`. El siguiente paso recomendado no es implementar features aisladas, sino consolidar primero la base de DI, scopes y pipeline, porque casi todos los demás requisitos dependen de eso.
