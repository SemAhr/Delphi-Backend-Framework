unit Http.ValueConverter;

interface

uses
  System.SysUtils,
  System.Rtti;

type
  TValueConverter = class
  public
    class function TryConvertString(
      const RawValue: string;
      const TargetType: TRttiType;
      out Value: TValue;
      out ErrorMessage: string
    ): Boolean; static;
  end;

implementation

uses
  System.DateUtils,
  System.TypInfo;

class function TValueConverter.TryConvertString(
  const RawValue: string;
  const TargetType: TRttiType;
  out Value: TValue;
  out ErrorMessage: string
): Boolean;
var
  IntValue: Integer;
  Int64Value: Int64;
  DoubleValue: Double;
  BoolValue: Boolean;
  EnumValue: Integer;
  FormatSettings: TFormatSettings;
begin
  Result := False;
  Value := TValue.Empty;
  ErrorMessage := '';

  if TargetType = nil then
  begin
    ErrorMessage := 'target type is not available';
    Exit;
  end;

  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';

  case TargetType.TypeKind of
    tkString, tkLString, tkWString, tkUString:
      begin
        Value := TValue.From<string>(RawValue);
        Exit(True);
      end;

    tkInteger:
      begin
        if not TryStrToInt(RawValue, IntValue) then
        begin
          ErrorMessage := 'must be a valid integer';
          Exit;
        end;

        Value := TValue.From<Integer>(IntValue);
        Exit(True);
      end;

    tkInt64:
      begin
        if not TryStrToInt64(RawValue, Int64Value) then
        begin
          ErrorMessage := 'must be a valid int64';
          Exit;
        end;

        Value := TValue.From<Int64>(Int64Value);
        Exit(True);
      end;

    tkFloat:
      begin
        if TargetType.Handle = TypeInfo(TDateTime) then
        begin
          var DateValue: TDateTime;

          if not TryISO8601ToDate(RawValue, DateValue, False) then
          begin
            ErrorMessage := 'must be a valid ISO-8601 datetime';
            Exit;
          end;

          Value := TValue.From<TDateTime>(DateValue);
          Exit(True);
        end;

        if not TryStrToFloat(RawValue, DoubleValue, FormatSettings) then
        begin
          ErrorMessage := 'must be a valid number';
          Exit;
        end;

        if TargetType.Handle = TypeInfo(Single) then
          Value := TValue.From<Single>(DoubleValue)
        else if TargetType.Handle = TypeInfo(Extended) then
          Value := TValue.From<Extended>(DoubleValue)
        else if TargetType.Handle = TypeInfo(Currency) then
          Value := TValue.From<Currency>(DoubleValue)
        else
          Value := TValue.From<Double>(DoubleValue);

        Exit(True);
      end;

    tkEnumeration:
      begin
        if TargetType.Handle = TypeInfo(Boolean) then
        begin
          if SameText(RawValue, 'true') or (RawValue = '1') then
          begin
            Value := TValue.From<Boolean>(True);
            Exit(True);
          end;

          if SameText(RawValue, 'false') or (RawValue = '0') then
          begin
            Value := TValue.From<Boolean>(False);
            Exit(True);
          end;

          ErrorMessage := 'must be a valid boolean';
          Exit;
        end;

        EnumValue := GetEnumValue(TargetType.Handle, RawValue);

        if EnumValue < 0 then
        begin
          ErrorMessage := 'must be a valid enum value';
          Exit;
        end;

        Value := TValue.FromOrdinal(TargetType.Handle, EnumValue);
        Exit(True);
      end;
  end;

  ErrorMessage := 'unsupported scalar parameter type';
end;

end.
