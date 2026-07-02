unit DeactivateReport.UseCase;

interface

uses
  DeactivateReport.UseCase.Port;

type
  TDeactivateReportUseCase = class(TInterfacedObject, IDeactivateReportUseCase)
  public
    function Execute(const AReportId: string): Boolean;
  end;

implementation

function TDeactivateReportUseCase.Execute(const AReportId: string): Boolean;
begin

end;

end.
