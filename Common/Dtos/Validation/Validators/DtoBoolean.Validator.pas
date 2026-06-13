unit DtoBoolean.Validator;

interface

uses
  System.Rtti,
  Dto.Validation.Context;

type
  TDtoBooleanValidator = class
  public
    class function TryValidate(
      const Context: TDtoValidationContext;
      out ParsedValue: TValue;
      out ErrorMessages: TArray<string>
    ): Boolean; static;
  end;

implementation

uses
  System.JSON;

class function TDtoBooleanValidator.TryValidate(
  const Context: TDtoValidationContext;
  out ParsedValue: TValue;
  out ErrorMessages: TArray<string>
): Boolean;
var
  BooleanValue: Boolean;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  SetLength(ErrorMessages, 0);

  if Context.JsonValue is TJSONTrue then
    BooleanValue := True
  else if Context.JsonValue is TJSONFalse then
    BooleanValue := False
  else
  begin
    ErrorMessages := ['must be a boolean'];
    Exit;
  end;

  ParsedValue := TValue.From<Boolean>(BooleanValue);
  Result := True;
end;

end.
