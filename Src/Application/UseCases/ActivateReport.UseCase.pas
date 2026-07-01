unit ActivateReport.UseCase;

interface

uses
  ActivateReport.UseCase.Port,
  ActivateReport.Dto;

type
  TActivateReportUseCase = class(TInterfacedObject, IActivateReportUseCase)
  public
    function Execute(const ARequestDto: TActivateReportDto): Boolean;
    function Test(const ARequestDto: TActivateReportDto): Boolean;
  end;

implementation

{ TActivateReportUseCase }

function TActivateReportUseCase.Execute(const ARequestDto: TActivateReportDto): Boolean;
begin

end;

function TActivateReportUseCase.Test(const ARequestDto: TActivateReportDto): Boolean;
begin

end;

end.
