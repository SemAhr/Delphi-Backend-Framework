unit DtoString.Validator;

interface

uses
  System.Rtti,
  Dto.Validation.Context;

type
  TDtoStringValidator = class
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
  System.Generics.Collections,
  System.JSON,
  System.Variants,
  System.Classes,
  RttiAttribute.Helpers,
  Dto.Attributes;

class function TDtoStringValidator.TryValidate(
  const Context: TDtoValidationContext;
  out ParsedValue: TValue;
  out ErrorMessages: TArray<string>
): Boolean;
var
  StringValue: string;
  LengthRule: LengthAttribute;
  IsInRule: IsInAttribute;
  LocalErrors: TList<string>;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  SetLength(ErrorMessages, 0);

  LocalErrors := TList<string>.Create;
  try
    if not (Context.JsonValue is TJSONString) then
    begin
      ErrorMessages := ['must be a string'];
      Exit;
    end;

    StringValue := TJSONString(Context.JsonValue).Value;

    if TRttiAttributeHelpers.HasAttribute<RequiredAttribute>(Context.PropertyInfo) and
       (Trim(StringValue) = '') then
      LocalErrors.Add('cannot be empty');

    if TRttiAttributeHelpers.TryGetAttribute<LengthAttribute>(
      Context.PropertyInfo,
      LengthRule
    ) then
    begin
      if (LengthRule.MinLength >= 0) and
         (LengthRule.MinLength = LengthRule.MaxLength) then
      begin
        if LengthRule.MinLength <> StringValue.Length then
          LocalErrors.Add('length must be ' + LengthRule.MinLength.ToString);
      end
      else
      begin
        if (LengthRule.MinLength >= 0) and
           (StringValue.Length < LengthRule.MinLength) then
          LocalErrors.Add('length must be >= ' + LengthRule.MinLength.ToString);

        if (LengthRule.MaxLength >= 0) and
           (StringValue.Length > LengthRule.MaxLength) then
          LocalErrors.Add('length must be <= ' + LengthRule.MaxLength.ToString);
      end;
    end;

    if TRttiAttributeHelpers.HasAttribute<IsNumberStringAttribute>(
      Context.PropertyInfo
    ) then
    begin
      for var Index := 1 to Length(StringValue) do
      begin
        if not (StringValue[Index] in ['0'..'9']) then
        begin
          LocalErrors.Add('must contain only digits');
          Break;
        end;
      end;
    end;

    if TRttiAttributeHelpers.TryGetAttribute<IsInAttribute>(
      Context.PropertyInfo,
      IsInRule
    ) then
    begin
      var HasAllowedValue := False;
      var AllowedValuesText := TStringList.Create;
      try
        AllowedValuesText.StrictDelimiter := True;
        AllowedValuesText.Delimiter := ',';

        for var AllowedValue in IsInRule.Values do
        begin
          AllowedValuesText.Add(VarToStr(AllowedValue));

          if SameText(StringValue, VarToStr(AllowedValue)) then
            HasAllowedValue := True;
        end;

        if not HasAllowedValue then
          LocalErrors.Add('must be one of: ' + AllowedValuesText.DelimitedText);
      finally
        AllowedValuesText.Free;
      end;
    end;

    if LocalErrors.Count > 0 then
    begin
      ErrorMessages := LocalErrors.ToArray;
      Exit;
    end;

    ParsedValue := TValue.From<string>(StringValue);
    Result := True;
  finally
    LocalErrors.Free;
  end;
end;

end.
