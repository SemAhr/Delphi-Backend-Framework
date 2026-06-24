unit Date.Helpers;

interface

uses
  System.SysUtils;

type
  TDateHelpers = class
    public
      class function GetPreviousMonth(const Date: TDateTime): TDateTime; static;
      class function GetNextMonth(const Date: TDateTime): TDateTime; static;
      class function TryParseExpectedDate(const Value: string; out DateValue: TDateTime): Boolean; static;

      class function LocalToUtc(const LocalDateTime: TDateTime): TDateTime; static;
      class function UtcToLocal(const UtcDateTime: TDateTime): TDateTime; static;

      class function IsoUtcStringToUtc(const Value: string): TDateTime; static;
      class function IsoLocalStringToUtc(const Value: string): TDateTime; static;

      class function IsoUtcStringToLocal(const Value: string): TDateTime; static;
      class function TryIsoUtcStringToLocal(const Value: string; out Date: TDateTime): Boolean;

      class function IsoLocalStringToLocal(const Value: string): TDateTime; static;

      class function LocalToUtcIsoString(const LocalDateTime: TDateTime): string; static;
      class function UtcToUtcIsoString(const UtcDateTime: TDateTime): string; static;
  end;

implementation

uses
  System.DateUtils,
  System.Math;

class function TDateHelpers.GetNextMonth(const Date: TDateTime): TDateTime;
var
  TargetDate: TDateTime;
  TargetYear: Word;
  TargetMonth: Word;
  TargetDay: Word;
begin
  TargetDate := IncMonth(Date, 1);

  TargetYear := YearOf(TargetDate);
  TargetMonth := MonthOf(TargetDate);
  TargetDay := Min(DayOf(Date), DaysInAMonth(TargetYear, TargetMonth));

  Result := EncodeDate(TargetYear, TargetMonth, TargetDay);
end;

class function TDateHelpers.GetPreviousMonth(const Date: TDateTime): TDateTime;
var
  TargetDate: TDateTime;
  TargetYear: Word;
  TargetMonth: Word;
  TargetDay: Word;
begin
  TargetDate := IncMonth(Date, -1);

  TargetYear := YearOf(TargetDate);
  TargetMonth := MonthOf(TargetDate);
  TargetDay := Min(DayOf(Date), DaysInAMonth(TargetYear, TargetMonth));

  Result := EncodeDate(TargetYear, TargetMonth, TargetDay);
end;

class function TDateHelpers.TryParseExpectedDate(const Value: string; out DateValue: TDateTime): Boolean;
var
  FormatSettings: TFormatSettings;
  NormalizedValue: string;
begin
  DateValue := 0;

  NormalizedValue := Trim(Value);
  NormalizedValue := StringReplace(NormalizedValue, '-', '/', [rfReplaceAll]);
  NormalizedValue := StringReplace(NormalizedValue, '.', '/', [rfReplaceAll]);

  FormatSettings := TFormatSettings.Create;
  FormatSettings.DateSeparator := '/';
  FormatSettings.ShortDateFormat := 'dd/mm/yyyy';

  Result := TryStrToDate(NormalizedValue, DateValue, FormatSettings);
end;

class function TDateHelpers.LocalToUtc(const LocalDateTime: TDateTime): TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(LocalDateTime);
end;

class function TDateHelpers.UtcToLocal(const UtcDateTime: TDateTime): TDateTime;
begin
  Result := TTimeZone.Local.ToLocalTime(UtcDateTime);
end;

class function TDateHelpers.IsoUtcStringToUtc(const Value: string): TDateTime;
begin
  Result := ISO8601ToDate(Value, True);
end;

class function TDateHelpers.IsoLocalStringToUtc(const Value: string): TDateTime;
begin
  Result := LocalToUtc(ISO8601ToDate(Value, False));
end;

class function TDateHelpers.IsoUtcStringToLocal(const Value: string): TDateTime;
begin
  Result := UtcToLocal(ISO8601ToDate(Value, True));
end;

class function TDateHelpers.TryIsoUtcStringToLocal(const Value: string; out Date: TDateTime): Boolean;
begin
  Result := False;

  try
    Date := IsoUtcStringToLocal(Value);
    Result := True;
  except
  end;
end;

class function TDateHelpers.IsoLocalStringToLocal(const Value: string): TDateTime;
begin
  Result := ISO8601ToDate(Value, False);
end;

class function TDateHelpers.LocalToUtcIsoString(const LocalDateTime: TDateTime): string;
begin
  Result := DateToISO8601(LocalToUtc(LocalDateTime), True);
end;

class function TDateHelpers.UtcToUtcIsoString(const UtcDateTime: TDateTime): string;
begin
  Result := DateToISO8601(UtcDateTime, True);
end;

end.
