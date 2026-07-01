unit Utils.Controller;

interface

uses
  Http.Controller.Port,
  Http.Attributes,
  Http.Parameter.Attributes,
  Success.Dto;

type
  [Route('/utils')]
  TUtilsController = class(TInterfacedObject, IController)
  private
  public
    [Get('/health')]
    function Health: TSuccessDto;
  end;

implementation

{ TUtilsController }

function TUtilsController.Health: TSuccessDto;
begin
  Result := TSuccessDto.Create;
  Result.Message := 'OK';
end;

end.
