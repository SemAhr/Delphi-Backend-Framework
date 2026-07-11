unit CustomExceptions;

interface

uses
  System.SysUtils;

type
  EPuiException = class(Exception)
  private
    FStatusCode: Integer;
    FBody: string;
  public
    constructor Create(const StatusCode: Integer; const Body: string);
  end;

implementation

constructor EPuiException.Create(const StatusCode: Integer; const Body: string);
begin
  FStatusCode := StatusCode;
  FBody := Body;
end;

end.
