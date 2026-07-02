unit Success.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TSuccessDto = class(TInterfacedObject, IDto)
  private
    FMessage: string;
  public
    [JsonName('message')]
    property Message: string read FMessage write FMessage;
  end;

implementation

end.
