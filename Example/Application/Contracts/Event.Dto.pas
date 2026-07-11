unit Event.Dto;

interface

uses
  Dto.Attributes,
  Match.Dto;

type
  TEventDto = record
    [JsonName('tipo_evento')]
    EventType: string;

    [JsonName('fecha_evento')]
    EventDate: string;

    [JsonName('descripcion_lugar_evento')]
    LocationDescription: string;

    [JsonName('domicilio')]
    Address: TAddressDto;
  end;

implementation

end.
