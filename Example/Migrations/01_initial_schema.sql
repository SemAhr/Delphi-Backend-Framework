CREATE TYPE IF NOT EXISTS fase_busqueda AS ENUM ('FASE_1', 'FASE_2', 'FASE_3');

CREATE TYPE IF NOT EXISTS sexo_asignado AS ENUM ('H', 'M', 'X');

CREATE TYPE IF NOT EXISTS entidad_federativa AS ENUM (
    'AGUASCALIENTES',
    'BAJA CALIFORNIA',
    'BAJA CALIFORNIA SUR',
    'CAMPECHE',
    'CHIAPAS',
    'CHIHUAHUA',
    'CDMX',
    'COAHUILA',
    'COLIMA',
    'DURANGO',
    'GUANAJUATO',
    'GUERRERO',
    'HIDALGO',
    'JALISCO',
    'MEXICO',
    'MICHOACAN',
    'MORELOS',
    'NAYARIT',
    'NUEVO LEON',
    'OAXACA',
    'PUEBLA',
    'QUERETARO',
    'QUINTANA ROO',
    'SAN LUIS POTOSI',
    'SINALOA',
    'SONORA',
    'TABASCO',
    'TAMAULIPAS',
    'TLAXCALA',
    'VERACRUZ',
    'YUCATAN',
    'ZACATECAS',
    'FORANEO',
    'DESCONOCIDO'
);

CREATE TYPE IF NOT EXISTS estatus_reporte AS ENUM (
    'RECIBIDO',
    'FASE_1_EN_PROCESO',
    'FASE_1_COMPLETADA',
    'FASE_2_EN_PROCESO',
    'FASE_2_COMPLETADA',
    'FASE_3_EN_PROCESO',
    'FASE_3_COMPLETADA',
    'FINALIZADO'
);

CREATE TYPE IF NOT EXISTS origen_reporte AS ENUM (
    'ACTIVAR_REPORTE',
    'REPORTES'
);

CREATE TYPE IF NOT EXISTS tipo_evento AS ENUM (
    'N/A'
);

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    correo TEXT UNIQUE NOT NULL,
    contrasena TEXT NOT NULL,

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT usuarios_correo_no_vacio CHECK (btrim(correo) <> ''),
    CONSTRAINT usuarios_contrasena_no_vacia CHECK (btrim(contrasena) <> '')
);

CREATE TABLE IF NOT EXISTS reportes (
    id TEXT PRIMARY KEY NOT NULL,
    curp TEXT NOT NULL,

    nombre TEXT,
    primer_apellido TEXT,
    segundo_apellido TEXT,
    fecha_nacimiento DATE,

    fecha_desaparicion DATE,
    lugar_nacimiento entidad_federativa NOT NULL DEFAULT 'DESCONOCIDO',
    sexo_asignado sexo_asignado,

    telefono TEXT,
    correo TEXT,

    direccion TEXT,
    calle TEXT,
    numero TEXT,
    colonia TEXT,
    codigo_postal TEXT,
    municipio_o_alcaldia TEXT,
    estado entidad_federativa,

    estatus estatus_reporte NOT NULL DEFAULT 'RECIBIDO',
    origen origen_reporte NOT NULL DEFAULT 'REPORTES',

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT reportes_id_no_vacio CHECK (btrim(id) <> ''),
    CONSTRAINT reportes_curp_no_vacio CHECK (btrim(curp) <> ''),
    CONSTRAINT reportes_correo_no_vacio CHECK (correo IS NULL OR btrim(correo) <> ''),
    CONSTRAINT reportes_telefono_no_vacio CHECK (telefono IS NULL OR btrim(telefono) <> '')
);

CREATE TABLE IF NOT EXISTS eventos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    reporte_id TEXT NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,

    tipo tipo_evento NOT NULL DEFAULT 'N/A',
    fecha_evento TIMESTAMP NOT NULL,

    datos JSONB NOT NULL DEFAULT '{}'::jsonb,

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT eventos_datos_objeto CHECK (jsonb_typeof(datos) = 'object')
);

CREATE TABLE IF NOT EXISTS pui_peticiones (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    reporte_id TEXT REFERENCES reportes(id) ON DELETE SET NULL,

    ruta TEXT NOT NULL,
    metodo TEXT NOT NULL DEFAULT 'POST',

    solicitud JSONB,
    codigo_estado INTEGER,
    respuesta JSONB,
    mensaje_error TEXT,
    exitosa BOOLEAN NOT NULL DEFAULT FALSE,

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pui_peticiones_ruta_no_vacia CHECK (btrim(ruta) <> ''),
    CONSTRAINT pui_peticiones_metodo_no_vacio CHECK (btrim(metodo) <> ''),
    CONSTRAINT pui_peticiones_codigo_estado_valido CHECK (codigo_estado IS NULL OR codigo_estado BETWEEN 100 AND 599),
    CONSTRAINT pui_peticiones_resultado_registrado CHECK (codigo_estado IS NOT NULL OR respuesta IS NOT NULL OR mensaje_error IS NOT NULL),
    CONSTRAINT pui_peticiones_mensaje_error_no_vacio CHECK (mensaje_error IS NULL OR btrim(mensaje_error) <> '')
);

CREATE TABLE IF NOT EXISTS pui_intentos_evento (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    evento_id UUID NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
    pui_peticion_id UUID NOT NULL REFERENCES pui_peticiones(id) ON DELETE CASCADE,

    intento INTEGER NOT NULL,

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pui_intentos_evento_intento_positivo CHECK (intento > 0),
    CONSTRAINT pui_intentos_evento_evento_intento_unico UNIQUE (evento_id, intento),
    CONSTRAINT pui_intentos_evento_peticion_unica UNIQUE (pui_peticion_id)
);

CREATE TABLE IF NOT EXISTS api_peticiones (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    ip_origen TEXT NOT NULL,

    ruta TEXT NOT NULL,
    metodo TEXT NOT NULL DEFAULT 'POST',
    datos JSONB NOT NULL DEFAULT '{}'::jsonb,
    codigo_estado INTEGER,
    respuesta JSONB,
    mensaje_error TEXT,

    creado_el TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT api_peticiones_ip_origen_no_vacia CHECK (btrim(ip_origen) <> ''),
    CONSTRAINT api_peticiones_ruta_no_vacia CHECK (btrim(ruta) <> ''),
    CONSTRAINT api_peticiones_metodo_no_vacio CHECK (btrim(metodo) <> ''),
    CONSTRAINT api_peticiones_datos_objeto CHECK (jsonb_typeof(datos) = 'object'),
    CONSTRAINT api_peticiones_codigo_estado_valido CHECK (codigo_estado IS NULL OR codigo_estado BETWEEN 100 AND 599),
    CONSTRAINT api_peticiones_resultado_registrado CHECK (codigo_estado IS NOT NULL OR respuesta IS NOT NULL OR mensaje_error IS NOT NULL),
    CONSTRAINT api_peticiones_mensaje_error_no_vacio CHECK (mensaje_error IS NULL OR btrim(mensaje_error) <> '')
);

CREATE INDEX IF NOT EXISTS idx_reportes_curp
ON reportes(curp);

CREATE INDEX IF NOT EXISTS idx_reportes_estatus
ON reportes(estatus);

CREATE INDEX IF NOT EXISTS idx_reportes_origen
ON reportes(origen);

CREATE INDEX IF NOT EXISTS idx_eventos_reporte_id
ON eventos(reporte_id);

CREATE INDEX IF NOT EXISTS idx_eventos_tipo
ON eventos(tipo);

CREATE INDEX IF NOT EXISTS idx_pui_peticiones_reporte_id
ON pui_peticiones(reporte_id);

CREATE INDEX IF NOT EXISTS idx_pui_peticiones_ruta
ON pui_peticiones(ruta);

CREATE INDEX IF NOT EXISTS idx_pui_peticiones_exitosa
ON pui_peticiones(exitosa);

CREATE INDEX IF NOT EXISTS idx_pui_intentos_evento_evento_id
ON pui_intentos_evento(evento_id);

CREATE INDEX IF NOT EXISTS idx_api_peticiones_ruta
ON api_peticiones(ruta);

CREATE INDEX IF NOT EXISTS idx_api_peticiones_codigo_estado
ON api_peticiones(codigo_estado);
