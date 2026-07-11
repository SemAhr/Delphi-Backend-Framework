unit Match.Dto;

interface

uses
  Dto.Attributes;

type
  TFullNameDto = record
    [JsonName('nombre')]
    FirstName: string;

    [JsonName('primer_apellido')]
    LastName: string;

    [JsonName('segundo_apellido')]
    SecondLastName: string;
  end;

  TAddressDto = record
    [JsonName('direccion')]
    Address: string;

    [JsonName('calle')]
    Street: string;

    [JsonName('numero')]
    Number: string;

    [JsonName('colonia')]
    Neighborhood: string;

    [JsonName('codigo_postal')]
    PostalCode: string;

    [JsonName('municipio_o_alcaldia')]
    MunicipalityOrBorough: string;

    [JsonName('entidad_federativa')]
    State: string;
  end;

  TFingerprintsDto = record
    [JsonName('rone')]
    RightThumb: string;

    [JsonName('rtwo')]
    RightIndex: string;

    [JsonName('rthree')]
    RightMiddle: string;

    [JsonName('rfour')]
    RightRing: string;

    [JsonName('rfive')]
    RightLittle: string;

    [JsonName('lone')]
    LeftThumb: string;

    [JsonName('ltwo')]
    LeftIndex: string;

    [JsonName('lthree')]
    LeftMiddle: string;

    [JsonName('lfour')]
    LeftRing: string;

    [JsonName('lfive')]
    LeftLittle: string;

    [JsonName('rpalm')]
    RightPalm: string;

    [JsonName('lpalm')]
    LeftPalm: string;
  end;

  TMatchDto = record
    [JsonName('curp')]
    Curp: string;

    [JsonName('nombre_completo')]
    FullName: TFullNameDto;

    [JsonName('fecha_nacimiento')]
    BirthDate: string; { YYYY-MM-DD }

    [JsonName('lugar_nacimiento')]
    BirthPlace: string; { Entidad federativa, FORÁNEO o DESCONOCIDO }

    [JsonName('sexo_asignado')]
    AssignedSex: string; { H, M, X }

    [JsonName('telefono')]
    Phone: string;

    [JsonName('correo')]
    Email: string;

    [JsonName('domicilio')]
    Address: TAddressDto;

    [JsonName('fotos')]
    Photos: TArray<string>;

    [JsonName('formato_fotos')]
    PhotosFormat: string;

    [JsonName('huellas')]
    Fingerprints: TFingerprintsDto;

    [JsonName('formato_huellas')]
    FingerprintsFormat: string;

    [JsonName('id')]
    Id: string;

    [JsonName('institucion_id')]
    InstitutionId: string;

    [JsonName('fase_busqueda')]
    SearchPhase: string; { 1 }
  end;

implementation

end.
