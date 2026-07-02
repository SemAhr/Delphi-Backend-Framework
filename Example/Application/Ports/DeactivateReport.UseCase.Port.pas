unit DeactivateReport.UseCase.Port;

interface

type
  IDeactivateReportUseCase = interface
    ['{785a1efc-408a-4b5d-8637-f4ef6e1712fa}']

    function Execute(const AReportId: string): Boolean;
  end;

implementation

end.
