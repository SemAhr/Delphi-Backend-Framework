unit Http.Middleware.Attributes;

interface

uses
  System.SysUtils;

type
  UseMiddlewareAttribute = class(TCustomAttribute)
  private
    FMiddlewareType: TClass;
    FOrder: Integer;
  public
    constructor Create(const AMiddlewareType: TClass; const AOrder: Integer = 0);

    property MiddlewareType: TClass read FMiddlewareType;
    property Order: Integer read FOrder;
  end;

implementation

constructor UseMiddlewareAttribute.Create(const AMiddlewareType: TClass; const AOrder: Integer);
begin
  inherited Create;

  if AMiddlewareType = nil then
    raise Exception.Create('Middleware type is required.');

  FMiddlewareType := AMiddlewareType;
  FOrder := AOrder;
end;

end.
