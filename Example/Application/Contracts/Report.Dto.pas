unit Report.Dto;

interface

uses
  Dto.Attributes;

type
  TReportDto = record
    [JsonName('id')]
    Id: string;

    [JsonName('curp')]
    Curp: string;

    [JsonName('nombre')]
    Name: string;

    [JsonName('primer_apellido')]
    FirstSurname: string;

    [JsonName('segundo_apellido')]
    SecondSurname: string;

    [JsonName('fecha_nacimiento')]
    BirthDate: string;

    [JsonName('fecha_desaparicion')]
    DisappearanceDate: string;

    [JsonName('fecha_registro')]
    RegistrationDate: string;

    [JsonName('lugar_nacimiento')]
    BirthPlace: string;

    [JsonName('sexo_asignado')]
    AssignedSex: string;
  end;

implementation

end.
