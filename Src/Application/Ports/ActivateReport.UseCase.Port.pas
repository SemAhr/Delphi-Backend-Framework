unit ActivateReport.UseCase.Port;

interface

uses
  ActivateReport.Dto;

type
  IActivateReportUseCase = interface
    ['{785a1efc-408a-4b5d-8637-f4ef6e1712fa}']

    function Execute(const ARequestDto: TActivateReportDto): Boolean;
    function Test(const ARequestDto: TActivateReportDto): Boolean;
  end;

implementation

end.
