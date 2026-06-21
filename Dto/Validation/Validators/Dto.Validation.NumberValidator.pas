unit Dto.Validation.NumberValidator;

interface

uses
  System.Rtti,
  Dto.Validation.Context;

type
  TDtoNumberValidator = class
  public
    class function TryValidate(
      const AContext: TDtoValidationContext;
      out AParsedValue: TValue;
      out AErrorMessages: TArray<string>
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Math,
  System.JSON,
  System.Classes,
  System.Variants,
  RttiAttribute.Helpers,
  Dto.Attributes,
  Dto.TypeInspector;

class function TDtoNumberValidator.TryValidate(
  const AContext: TDtoValidationContext;
  out AParsedValue: TValue;
  out AErrorMessages: TArray<string>
): Boolean;
var
  NumberValue: Double;
  MinRule: MinAttribute;
  MaxRule: MaxAttribute;
  IsInRule: IsInAttribute;
  LocalErrors: TList<string>;
begin
  Result := False;
  AParsedValue := TValue.Empty;
  SetLength(AErrorMessages, 0);

  LocalErrors := TList<string>.Create;
  try
    if not (AContext.JsonValue is TJSONNumber) then
    begin
      if TDtoTypeInspector.IsIntegerType(AContext.PropertyInfo) or
         TDtoTypeInspector.IsInt64Type(AContext.PropertyInfo) then
        AErrorMessages := ['must be an integer']
      else
        AErrorMessages := ['must be a number'];

      Exit;
    end;

    NumberValue := TJSONNumber(AContext.JsonValue).AsDouble;

    if (TDtoTypeInspector.IsIntegerType(AContext.PropertyInfo) or
        TDtoTypeInspector.IsInt64Type(AContext.PropertyInfo)) and
       (Frac(NumberValue) <> 0) then
    begin
      AErrorMessages := ['must be an integer'];
      Exit;
    end;

    if TRttiAttributeHelpers.TryGetAttribute<MinAttribute>(
      AContext.PropertyInfo,
      MinRule
    ) and (NumberValue < MinRule.Value) then
    begin
      if TDtoTypeInspector.IsIntegerType(Context.PropertyInfo) or
         TDtoTypeInspector.IsInt64Type(Context.PropertyInfo) then
        LocalErrors.Add('must be >= ' + Trunc(MinRule.Value).ToString)
      else
        LocalErrors.Add('must be >= ' + FloatToStr(MinRule.Value));
    end;

    if TRttiAttributeHelpers.TryGetAttribute<MaxAttribute>(
      Context.PropertyInfo,
      MaxRule
    ) and (NumberValue > MaxRule.Value) then
    begin
      if TDtoTypeInspector.IsIntegerType(Context.PropertyInfo) or
         TDtoTypeInspector.IsInt64Type(Context.PropertyInfo) then
        LocalErrors.Add('must be <= ' + Trunc(MaxRule.Value).ToString)
      else
        LocalErrors.Add('must be <= ' + FloatToStr(MaxRule.Value));
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

          if VarIsNumeric(AllowedValue) and
             SameValue(NumberValue, Double(AllowedValue)) then
            HasAllowedValue := True;
        end;

        if not HasAllowedValue then
          LocalErrors.Add('must be one of: ' + AllowedValuesText.DelimitedText);
      finally
        AllowedValuesText.Free;
      end;
    end;

    {if TRttiAttributeHelpers.HasAttribute<CurrenciesRuleAttribute>(
      Context.PropertyInfo
    ) then
    begin
      var HasAllowedValue := False;
      var AllowedRuleValues := Config.Rules.AllowedDenominations;

      var AllowedValuesText := TStringList.Create;
      try
        AllowedValuesText.StrictDelimiter := True;
        AllowedValuesText.Delimiter := ',';

        for var AllowedRuleValue in AllowedRuleValues do
        begin
          AllowedValuesText.Add(CurrToStr(AllowedRuleValue));

          if SameValue(NumberValue, Double(AllowedRuleValue)) then
            HasAllowedValue := True;
        end;

        if not HasAllowedValue then
          LocalErrors.Add('must be one of: ' + AllowedValuesText.DelimitedText);
      finally
        AllowedValuesText.Free;
      end;
    end;}

    {if TRttiAttributeHelpers.HasAttribute<MaxOperationAmountRuleAttribute>(
      Context.PropertyInfo
    ) then
    begin
      var MaxAllowedAmount := Config.Rules.MaxOperationAmount;

      if (MaxAllowedAmount > 0) and (NumberValue > Double(MaxAllowedAmount)) then
        LocalErrors.Add('must be <= ' + CurrToStr(MaxAllowedAmount));
    end;}

    if LocalErrors.Count > 0 then
    begin
      ErrorMessages := LocalErrors.ToArray;
      Exit;
    end;

    if TDtoTypeInspector.IsCurrencyType(Context.PropertyInfo) then
    begin
      ParsedValue := TValue.From<Currency>(Currency(NumberValue));
      Exit(True);
    end;

    case Context.PropertyInfo.PropertyType.TypeKind of
      tkInteger:
        ParsedValue := TValue.From<Integer>(Trunc(NumberValue));

      tkInt64:
        ParsedValue := TValue.From<Int64>(Int64(Trunc(NumberValue)));

      tkFloat:
        ParsedValue := TValue.From<Double>(NumberValue);
    else
      ParsedValue := TValue.From<Double>(NumberValue);
    end;

    Result := True;
  finally
    LocalErrors.Free;
  end;
end;

end.
