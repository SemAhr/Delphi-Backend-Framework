unit Dto.Validation.RequiredValidator;

interface

uses
  System.Rtti,
  System.JSON;

type
  TDtoRequiredValidator = class
  public
    class function TryValidate(
      const PropertyInfo: TRttiProperty;
      const JsonValue: TJSONValue;
      out ErrorMessage: string
    ): Boolean; static;
  end;

implementation

uses
  Shared.RttiAttribute.Helpers,
  Dto.Attributes;

class function TDtoRequiredValidator.TryValidate(
  const PropertyInfo: TRttiProperty;
  const JsonValue: TJSONValue;
  out ErrorMessage: string
): Boolean;
begin
  Result := True;
  ErrorMessage := '';

  if JsonValue <> nil then
    Exit;

  if TRttiAttributeHelpers.HasAttribute<RequiredAttribute>(PropertyInfo) then
  begin
    ErrorMessage := 'is required';
    Exit(False);
  end;
end;

end.
