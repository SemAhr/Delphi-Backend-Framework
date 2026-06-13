unit DtoDate.Validator;

interface

uses
  System.Rtti,
  Dto.Validation.Context;

type
  TDtoDateValidator = class
  public
    class function TryValidate(
      const Context: TDtoValidationContext;
      out ParsedValue: TValue;
      out ErrorMessages: TArray<string>
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  Dto.TypeInspector;

class function TDtoDateValidator.TryValidate(
  const Context: TDtoValidationContext;
  out ParsedValue: TValue;
  out ErrorMessages: TArray<string>
): Boolean;
var
  DateValue: TDateTime;
  DateTypeMessage: string;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  SetLength(ErrorMessages, 0);

  DateTypeMessage := TDtoTypeInspector.GetDateTypeMessage(Context.PropertyInfo);

  if not (Context.JsonValue is TJSONString) then
  begin
    ErrorMessages := [DateTypeMessage];
    Exit;
  end;

  try
    DateValue := ISO8601ToDate(TJSONString(Context.JsonValue).Value, False);

    if TDtoTypeInspector.IsDateOnlyType(Context.PropertyInfo) then
      DateValue := Trunc(DateValue);

    ParsedValue := TValue.From<TDateTime>(DateValue);
    Result := True;
  except
    ErrorMessages := [DateTypeMessage];
  end;
end;

end.
