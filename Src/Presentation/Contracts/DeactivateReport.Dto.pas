unit DeactivateReport.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TDeactivateReportDto = class(TInterfacedObject, IDto)
  private
    FId: string;
  public
    [Required]
    [JsonName('id')]
    property Id: string read FId write FId;
  end;

implementation

end.
