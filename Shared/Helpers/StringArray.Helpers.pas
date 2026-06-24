unit StringArray.Helpers;

interface

uses
  System.SysUtils;

type
  TStringHelpers = class
  public
    class function StringToArray<T>(const Value: string; const Separator: string = ','): TArray<T>; static;
  end;

implementation

uses
  System.Rtti,
  System.TypInfo,
  AppExceptions;

class function TStringHelpers.StringToArray<T>(const Value: string; const Separator: string): TArray<T>;
var
  Parts: TArray<string>;
  Index: Integer;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  CurrentText: string;
  CurrentValue: TValue;
  FormatSettings: TFormatSettings;
  IntegerValue: Integer;
  Int64Value: Int64;
  DoubleValue: Double;
  CurrencyValue: Currency;
  BooleanValue: Boolean;
begin
  if Separator = '' then
    raise EMetadataException.Create('Separator cannot be empty');

  if Value.Trim = '' then
    Exit(nil);

  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.DateSeparator := '-';
  FormatSettings.TimeSeparator := ':';

  Parts := Value.Split([Separator], TStringSplitOptions.ExcludeEmpty);

  SetLength(Result, Length(Parts));

  RttiType := RttiContext.GetType(TypeInfo(T));
  if RttiType = nil then
    raise EMetadataException.Create('Could not resolve generic type.');

  for Index := 0 to High(Parts) do
  begin
    CurrentText := Trim(Parts[Index]);

    if RttiType.Handle = TypeInfo(string) then
      CurrentValue := TValue.From<string>(CurrentText)

    else if RttiType.Handle = TypeInfo(Integer) then
    begin
      if not TryStrToInt(CurrentText, IntegerValue) then
        raise EMetadataException.CreateFmt('Invalid integer array value: "%s".', [CurrentText]);

      CurrentValue := TValue.From<Integer>(IntegerValue);
    end

    else if RttiType.Handle = TypeInfo(Int64) then
    begin
      if not TryStrToInt64(CurrentText, Int64Value) then
        raise EMetadataException.CreateFmt('Invalid int64 array value: "%s".', [CurrentText]);

      CurrentValue := TValue.From<Int64>(Int64Value);
    end

    else if RttiType.Handle = TypeInfo(Double) then
    begin
      if not TryStrToFloat(CurrentText, DoubleValue, FormatSettings) then
        raise EMetadataException.CreateFmt('Invalid double array value: "%s".', [CurrentText]);

      CurrentValue := TValue.From<Double>(DoubleValue);
    end

    else if RttiType.Handle = TypeInfo(Currency) then
    begin
      if not TryStrToCurr(CurrentText, CurrencyValue, FormatSettings) then
        raise EMetadataException.CreateFmt('Invalid currency array value: "%s".', [CurrentText]);

      CurrentValue := TValue.From<Currency>(CurrencyValue);
    end

    else if RttiType.Handle = TypeInfo(Boolean) then
    begin
      if not TryStrToBool(CurrentText, BooleanValue) then
        raise EMetadataException.CreateFmt('Invalid boolean array value: "%s".', [CurrentText]);

      CurrentValue := TValue.From<Boolean>(BooleanValue);
    end

    else
      raise EMetadataException.CreateFmt(
        'Unsupported array element type: %s',
        [RttiType.Name]
      );

    Result[Index] := CurrentValue.AsType<T>();
  end;
end;

end.
