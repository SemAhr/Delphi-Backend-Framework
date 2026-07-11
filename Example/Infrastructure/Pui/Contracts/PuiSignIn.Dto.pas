unit PuiSignIn.Dto;

interface

uses
  Dto.Attributes;

type
  TPuiSignInRequestDto = record
    [JsonName('institucion_id')]
    InstitutionId: string;

    [JsonName('clave')]
    Password: string;
  end;


implementation

end.
