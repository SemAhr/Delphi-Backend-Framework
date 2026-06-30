# Guía de opciones y logger

El framework expone configuración mediante `IOptions<T>` y `TOptions<T>` en `Shared/Options/Options.Port.pas`.

La carga concreta de configuración del framework vive fuera de `Src`. El loader incluido en `Shared/Options/App.Options.Loader.pas` carga un record raíz `TAppOptions` desde JSON. El contenedor no depende de los detalles del JSON: solo ejecuta un loader que devuelve un record.

## Estructura base

```text
Shared/Options/Options.Port.pas       // IOptions<T>, TOptions<T>, TOptionsLoader<T>
Shared/Logging/Logger.Port.pas        // ILogger
Shared/Logging/Logger.Options.pas     // TLoggerOptions
Shared/Logging/Logger.pas             // TLogger
Shared/Options/App.Options.pas        // TAppOptions
Shared/Options/App.Options.Loader.pas
config/Config.json
```

## Configuración raíz

`TAppOptions` es el record raíz de configuración de la app:

```pascal
type
  TAppOptions = record
    Logger: TLoggerOptions;
  end;
```

Puedes agregar más secciones como campos del record:

```pascal
type
  TAppOptions = record
    Logger: TLoggerOptions;
    Jwt: TJwtOptions;
    Database: TDatabaseOptions;
  end;
```

## Loader JSON

El loader por defecto lee:

```text
./Config/Config.json
```

Ejemplo mínimo:

```json
{
  "Logger": {
    "LogLevel": "Info",
    "FilePath": "./logs/app.log"
  }
}
```

También se puede cargar un archivo custom y mezclarlo con el default:

```pascal
TAppOptionsLoader.LoadFromFile('./Config/Production.json');
```

El merge es recursivo para objetos JSON: si una sección existe en default y en override, solo se reemplazan los campos provistos por el override.

## Registro en el contenedor

`TAppContainer` configura por defecto el loader raíz:

```pascal
SetOptionsLoader<TAppOptions>(TAppOptionsLoader.LoadFromDefaultPath);
```

También registra por default la sección del logger:

```pascal
AddOptions<TLoggerOptions>('Logger');
```

Por eso, al crear el contenedor, la configuración queda preparada para cargarse automáticamente la primera vez que se resuelva una dependencia.

Para más secciones, registra el nombre del campo dentro de `TAppOptions`:

```pascal
AppContainer.AddOptions<TJwtOptions>('Jwt');
AppContainer.AddOptions<TDatabaseOptions>('Database');
```

El nombre debe coincidir con el campo del record raíz:

```pascal
TAppOptions = record
  Jwt: TJwtOptions;
  Database: TDatabaseOptions;
end;
```

## Consumo en dependencias

Las dependencias pueden pedir directamente la sección que necesitan:

```pascal
constructor TJwtService.Create(const AOptions: IOptions<TJwtOptions>);
begin
  FOptions := AOptions.Value;
end;
```

El contenedor ejecuta el loader una sola vez, de forma lazy, cuando se resuelve una dependencia por primera vez.

## Logger

`TLogger` consume:

```pascal
IOptions<TLoggerOptions>
```

`TLoggerOptions` espera:

```pascal
type
  TLoggerOptions = record
    LogLevel: string;
    FilePath: string;
  end;
```

Valores válidos para `LogLevel`:

- `Debug`
- `Info`
- `Warning`
- `Error`

El logger valida:

- que `LogLevel` no esté vacío;
- que `FilePath` no esté vacío;
- que el path del log sea válido;
- que el archivo pueda abrirse.

## Tipos soportados por Json.Helpers

`TAppOptionsLoader` usa:

```pascal
TJsonHelpers.ToRecord<TAppOptions>(JsonObject)
```

Por tanto, las secciones de options pueden usar los tipos soportados por `Json.Helpers.pas`, entre ellos:

- enteros y ordinales compatibles;
- `Single`, `Double`, `Extended`, `Currency`;
- `string`;
- `Char`;
- `Boolean`;
- enums desde strings;
- records anidados;
- dynamic arrays;
- clases desde JSON object, si tienen constructor default y propiedades públicas/publicadas escribibles;
- `TDateTime`;
- `TDate`;
- `TTime`;
- `TTimeSpan`;
- `TGUID`;
- `TBytes` desde Base64;
- `null`, que se convierte a valor default.

## Limitaciones y recomendaciones

Aunque `Json.Helpers` soporta clases, conviene evitar objetos con ownership complejo dentro de records de options.

Evita, salvo que tengas una razón clara:

```pascal
TObjectList<T>
TDictionary<TKey, TValue>
TStream
TComponent
TCustomAttribute
```

Motivo:

- los records se copian por valor;
- las clases se copian como referencias;
- el ownership puede quedar ambiguo;
- algunas colecciones no están pensadas para deserializarse como options simples;
- pueden requerir constructores o propiedades que `Json.Helpers` no puede poblar correctamente.

Preferible:

```pascal
type
  TJwtOptions = record
    Secret: string;
    ExpirationMinutes: Integer;
  end;

  THeadersOptions = record
    AllowedHeaders: TArray<string>;
  end;
```

Si necesitas configuración runtime como middlewares, attributes o componentes complejos, usa los registros del contenedor:

```pascal
Container.Use(TSomeMiddleware);
Container.AddAttributeHandler(TSomeHandler);
```

en lugar de guardarlos dentro de `TAppOptions`.

## Resumen

- La app define `TAppOptions`.
- La app define o usa un loader que devuelve `TAppOptions`.
- El contenedor ejecuta ese loader una sola vez.
- `AddOptions<T>('FieldName')` expone sub-records como `IOptions<T>`.
- El logger usa por defecto la sección `Logger`.
