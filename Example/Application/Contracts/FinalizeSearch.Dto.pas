unit FinalizeSearch.Dto;

interface

uses
  Dto.Attributes;

type
  TFinalizeSearchDto = record
    [JsonName('institucion_id')]
    InstitutionId: string;

    [JsonName('id')]
    Id: string;
  end;

implementation

end.
