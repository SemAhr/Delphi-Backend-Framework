unit Dto.Attributes;

interface

uses
  System.SysUtils,
  System.Variants;

type
  JsonNameAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const Name: string);
    property Name: string read FName;
  end;

  RequiredAttribute = class(TCustomAttribute);

  IsDateAttribute = class(TCustomAttribute);
  IsDateTimeAttribute = class(TCustomAttribute);
  IsNumberStringAttribute = class(TCustomAttribute);

  LengthAttribute = class(TCustomAttribute)
  private
    FMinLength: Integer;
    FMaxLength: Integer;
  public
    constructor Create(const Length: Integer); overload;
    constructor Create(const MinLength, MaxLength: Integer); overload;

    property MinLength: Integer read FMinLength;
    property MaxLength: Integer read FMaxLength;
  end;

  MinAttribute = class(TCustomAttribute)
  private
    FValue: Double;
  public
    constructor Create(const Value: Double);
    property Value: Double read FValue;
  end;

  MaxAttribute = class(TCustomAttribute)
  private
    FValue: Double;
  public
    constructor Create(const Value: Double);
    property Value: Double read FValue;
  end;

  MinItemsAttribute = class(TCustomAttribute)
  private
    FValue: Integer;
  public
    constructor Create(const Value: Integer);
    property Value: Integer read FValue;
  end;

  MaxItemsAttribute = class(TCustomAttribute)
  private
    FValue: Integer;
  public
    constructor Create(const Value: Integer);
    property Value: Integer read FValue;
  end;

  IsInAttribute = class(TCustomAttribute)
  private
    FValues: TArray<Variant>;
  public
    constructor Create(const Values: TArray<Double>); overload;
    constructor Create(const Values: TArray<string>); overload;

    property Values: TArray<Variant> read FValues;
  end;

//  CurrenciesRuleAttribute = class(TCustomAttribute);

//  MaxOperationAmountRuleAttribute = class(TCustomAttribute);

implementation

uses
  AppExceptions,
  System.Math;

constructor JsonNameAttribute.Create(const Name: string);
var
  NormalizedName: string;
begin
  inherited Create;

  NormalizedName := Name.Trim;

  if NormalizedName.IsEmpty then
    raise EInvalidAttributeException.Create('JsonNameAttribute name cannot be empty.');

  FName := NormalizedName;
end;

constructor LengthAttribute.Create(const Length: Integer);
begin
  inherited Create;

  if Length <= 0 then
    raise EOutOfRangeAttributeException.Create('LengthAttribute length must be greater than zero.');

  FMinLength := Length;
  FMaxLength := Length;
end;

constructor LengthAttribute.Create(const MinLength, MaxLength: Integer);
begin
  inherited Create;

  if MinLength < 0 then
    raise EOutOfRangeAttributeException.Create('LengthAttribute min length cannot be less than zero.');

  if MaxLength <= 0 then
    raise EOutOfRangeAttributeException.Create('LengthAttribute max length must be greater than zero.');

  if MinLength > MaxLength then
    raise EInvalidAttributeException.Create('LengthAttribute min length cannot be greater than max length.');

  FMinLength := MinLength;
  FMaxLength := MaxLength;
end;

constructor MinAttribute.Create(const Value: Double);
begin
  inherited Create;

  if IsNan(Value) or IsInfinite(Value) then
    raise EInvalidAttributeException.Create('MinAttribute value must be a finite number.');

  FValue := Value;
end;

constructor MaxAttribute.Create(const Value: Double);
begin
  inherited Create;

  if IsNan(Value) or IsInfinite(Value) then
    raise EInvalidAttributeException.Create('MaxAttribute value must be a finite number.');

  FValue := Value;
end;

constructor MinItemsAttribute.Create(const Value: Integer);
begin
  inherited Create;

  if Value < 0 then
    raise EOutOfRangeAttributeException.Create('MinItemsAttribute value cannot be less than zero.');

  FValue := Value;
end;

constructor MaxItemsAttribute.Create(const Value: Integer);
begin
  inherited Create;

  if Value <= 0 then
    raise EOutOfRangeAttributeException.Create('MaxItemsAttribute value must be greater than zero.');

  FValue := Value;
end;

constructor IsInAttribute.Create(const Values: TArray<Double>);
begin
  inherited Create;

  if Length(Values) = 0 then
    raise EInvalidAttributeException.Create('IsInAttribute values cannot be empty.');

  SetLength(FValues, Length(Values));

  for var Index := 0 to High(Values) do
  begin
    if IsNan(Values[Index]) or IsInfinite(Values[Index]) then
      raise EInvalidAttributeException.Create(Format('IsInAttribute value at index %d must be a finite number.', [Index]));

    FValues[Index] := Values[Index];
  end;
end;

constructor IsInAttribute.Create(const Values: TArray<string>);
var
  NormalizedValue: string;
begin
  inherited Create;

  if Length(Values) = 0 then
    raise EInvalidAttributeException.Create('IsInAttribute values cannot be empty.');

  SetLength(FValues, Length(Values));

  for var Index := 0 to High(Values) do
  begin
    NormalizedValue := Values[Index].Trim;

    if NormalizedValue.IsEmpty then
      raise EInvalidAttributeException.Create(Format('IsInAttribute value at index %d cannot be empty.', [Index]));

    FValues[Index] := NormalizedValue;
  end;
end;

end.
