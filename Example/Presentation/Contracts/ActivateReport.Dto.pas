unit ActivateReport.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TActivateReportDto = class(TInterfacedObject, IDto)
  private
    FId: string;
    FCurp: string;
    FName: string;
    FFirstSurname: string;
    FSecondSurname: string;
    FDateOfBirth: TDate;
    FDateOfDisappearance: TDate;
    FPlaceOfBirth: string;
    FAssignedSex: string;
    FPhone: string;
    FEmail: string;
    FAddress: string;
    FStreet: string;
    FNumber: string;
    FNeighborhood: string;
    FPostalCode: string;
    FMunicipalityOrAlcaldia: string;
    FState: string;
  public
    [Required]
    [Length(36, 75)]
    [JsonName('id')]
    property Id: string read FId write FId;

    [Required]
    [Length(18)]
    [JsonName('curp')]
    property Curp: string read FCurp write FCurp;

    [JsonName('nombre')]
    [Length(0, 50)]
    property Name: string read FName write FName;

    [Length(0, 50)]
    [JsonName('primer_apellido')]
    property FirstSurname: string read FFirstSurname write FFirstSurname;

    [Length(0, 50)]
    [JsonName('segundo_apellido')]
    property SecondSurname: string read FSecondSurname write FSecondSurname;

    [IsDate]
    [JsonName('fecha_nacimiento')]
    property DateOfBirth: TDate read FDateOfBirth write FDateOfBirth;

    [IsDate]
    [JsonName('fecha_desaparicion')]
    property DateOfDisappearance: TDate read FDateOfDisappearance write FDateOfDisappearance;

    [Required]
    [JsonName('lugar_nacimiento')]
    property PlaceOfBirth: string read FPlaceOfBirth write FPlaceOfBirth;

    [JsonName('sexo_asignado')]
    property AssignedSex: string read FAssignedSex write FAssignedSex;

    [JsonName('telefono')]
    property Phone: string read FPhone write FPhone;

    [JsonName('correo')]
    property Email: string read FEmail write FEmail;

    [JsonName('direccion')]
    property Address: string read FAddress write FAddress;

    [JsonName('calle')]
    property Street: string read FStreet write FStreet;

    [JsonName('numero')]
    property Number: string read FNumber write FNumber;

    [JsonName('colonia')]
    property Neighborhood: string read FNeighborhood write FNeighborhood;

    [JsonName('codigo_postal')]
    property PostalCode: string read FPostalCode write FPostalCode;

    [JsonName('municipio_o_alcaldia')]
    property MunicipalityOrAlcaldia: string read FMunicipalityOrAlcaldia write FMunicipalityOrAlcaldia;

    [JsonName('entidad_federativa')]
    property State: string read FState write FState;
  end;

implementation

end.
