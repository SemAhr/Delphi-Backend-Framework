unit Pui.Port;

interface

uses
  Report.Dto,
  Match.Dto,
  Event.Dto,
  FinalizeSearch.Dto;

type
  IPui = interface
    ['{7198f9c8-e373-41a7-8fbc-4ef0cf68f7bc}']

    function GetAccessToken: string;

    function GetReports: TArray<TReportDto>;
    function ReportMatch(const MatchDto: TMatchDto): Boolean; { Fase 1 }
    function ReportEvent(const EventDto: TEventDto): Boolean; { Fase 2 and 3 }
    function FinalizeSearch(const FinalizeSearchDto: TFinalizeSearchDto): Boolean;
  end;

implementation

end.
