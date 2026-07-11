unit Pui.Options;

interface

uses
  System.TimeSpan,
  Options.Port;

type


  TPuiOptions = class(TOptionsSection)
  private
    FInstitutionId: string;
    FPassword: string;
    FBaseUrl: string;
    FSessionDuration: TTimeSpan;
    FSessionGraceWindow: TTimeSpan;

    function GetSectionName: string; override;
  public
    property SectionName: string read GetSectionName;
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property InstitutionId: string read FInstitutionId write FInstitutionId;
    property Password: string read FPassword write FPassword;
    property SessionDuration: TTimeSpan read FSessionDuration write FSessionDuration;
    property SessionGraceWindow: TTimeSpan read FSessionGraceWindow write FSessionGraceWindow;
  end;

implementation

function TPuiOptions.GetSectionName: string;
begin
  Result := 'Pui';
end;

end.
