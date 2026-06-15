unit Dto.Binder;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.JSON,
  Dto.Binder.Contract;

type
  TDtoBindingContext = record
  private
    FErrors: TList<string>;
  public
    class function Create: TDtoBindingContext; static;

    procedure Release;

    function ErrorCount: Integer;

    procedure AddError(const PropertyPath: string; const Message: string);
    procedure AddErrors(const PropertyPath: string; const Messages: TArray<string>);

    procedure RaiseIfHasErrors;
  end;

  TDtoBinder = class(TInterfacedObject, IDtoBinder)
  private
    procedure BindObject(
      const JsonObject: TJSONObject;
      const Instance: TObject;
      var BindingContext: TDtoBindingContext
    );

    function TryParseJsonValue(
      const JsonValue: TJSONValue;
      const TargetType: TRttiType;
      const PropertyPath: string;
      var BindingContext: TDtoBindingContext;
      out ParsedValue: TValue;
      out ErrorMessage: string
    ): Boolean;

    function TryParseScalarJsonValue(
      const JsonValue: TJSONValue;
      const TargetType: TRttiType;
      const PropertyPath: string;
      out ParsedValue: TValue;
      out ErrorMessage: string
    ): Boolean;

    function TryParseJsonArray(
      const JsonArray: TJSONArray;
      const TargetType: TRttiType;
      const PropertyPath: string;
      var BindingContext: TDtoBindingContext;
      out ParsedValue: TValue;
      out ErrorMessage: string
    ): Boolean;

    function TryParseJsonObject(
      const JsonObject: TJSONObject;
      const TargetType: TRttiType;
      const PropertyPath: string;
      var BindingContext: TDtoBindingContext;
      out ParsedValue: TValue;
      out ErrorMessage: string
    ): Boolean;

  public
    constructor Create;

    procedure ParseDto(
      const RawBody: string;
      const DtoClass: TClass;
      out Dto: TObject
    ); overload;

    function ParseDto<T: class>(const RawBody: string): T; overload;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Shared.AppExceptions,
  Dto.Metadata,
  Dto.Attributes,
  Dto.Validation.Context,
  Dto.TypeInspector,
  Dto.Validation.RequiredValidator,
  Dto.Validation.StringValidator,
  Dto.Validation.BooleanValidator,
  Dto.Validation.NumberValidator,
  Dto.Validation.DateValidator;

{ TDtoBindingContext }

class function TDtoBindingContext.Create: TDtoBindingContext;
begin
  Result.FErrors := TList<string>.Create;
end;

procedure TDtoBindingContext.Release;
begin
  FErrors.Free;
  FErrors := nil;
end;

function TDtoBindingContext.ErrorCount: Integer;
begin
  if FErrors = nil then
    Exit(0);

  Result := FErrors.Count;
end;

procedure TDtoBindingContext.AddError(const PropertyPath: string; const Message: string);
begin
  if FErrors = nil then
    FErrors := TList<string>.Create;

  FErrors.Add(PropertyPath + ' ' + Message);
end;

procedure TDtoBindingContext.AddErrors(
  const PropertyPath: string;
  const Messages: TArray<string>
);
begin
  for var Message in Messages do
    AddError(PropertyPath, Message);
end;

procedure TDtoBindingContext.RaiseIfHasErrors;
begin
  if ErrorCount = 0 then
    Exit;

  raise EBinderException.Create(FErrors.ToArray);
end;

{ TDtoBinder }

constructor TDtoBinder.Create;
begin
  inherited Create;
end;

procedure TDtoBinder.BindObject(
  const JsonObject: TJSONObject;
  const Instance: TObject;
  var BindingContext: TDtoBindingContext
);
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  ParsedValue: TValue;
  ErrorMessage: string;
  ErrorMessages: TArray<string>;
  PresenceErrorMessage: string;
begin
  if (JsonObject = nil) or (Instance = nil) then
    Exit;

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(Instance.ClassType);

  for var PropertyItem in RttiType.GetProperties do
  begin
    if not PropertyItem.IsWritable then
      Continue;

    var JsonFieldName := TDtoMetadata.GetJsonFieldName(PropertyItem);
    var JsonValue := JsonObject.Values[JsonFieldName];

    if not TDtoRequiredValidator.TryValidate(
      PropertyItem,
      JsonValue,
      PresenceErrorMessage
    ) then
    begin
      BindingContext.AddError(JsonFieldName, PresenceErrorMessage);
      Continue;
    end;

    if JsonValue = nil then
      Continue;

    var ValidationContext := TDtoValidationContext.Create(
      PropertyItem,
      JsonFieldName,
      JsonValue
    );

    try
      if TDtoTypeInspector.IsDateLikeType(PropertyItem) then
      begin
        if TDtoDateValidator.TryValidate(ValidationContext, ParsedValue, ErrorMessages) then
          PropertyItem.SetValue(Instance, ParsedValue)
        else
          BindingContext.AddErrors(JsonFieldName, ErrorMessages);
      end

      else if TDtoTypeInspector.IsBooleanType(PropertyItem) then
      begin
        if TDtoBooleanValidator.TryValidate(ValidationContext, ParsedValue, ErrorMessages) then
          PropertyItem.SetValue(Instance, ParsedValue)
        else
          BindingContext.AddErrors(JsonFieldName, ErrorMessages);
      end

      else if TDtoTypeInspector.IsStringType(PropertyItem) then
      begin
        if TDtoStringValidator.TryValidate(ValidationContext, ParsedValue, ErrorMessages) then
          PropertyItem.SetValue(Instance, ParsedValue)
        else
          BindingContext.AddErrors(JsonFieldName, ErrorMessages);
      end

      else if TDtoTypeInspector.IsNumericType(PropertyItem) then
      begin
        if TDtoNumberValidator.TryValidate(ValidationContext, ParsedValue, ErrorMessages) then
          PropertyItem.SetValue(Instance, ParsedValue)
        else
          BindingContext.AddErrors(JsonFieldName, ErrorMessages);
      end

      else
      begin
        if TryParseJsonValue(
          JsonValue,
          PropertyItem.PropertyType,
          JsonFieldName,
          BindingContext,
          ParsedValue,
          ErrorMessage
        ) then
        begin
          if not ParsedValue.IsEmpty then
            PropertyItem.SetValue(Instance, ParsedValue);
        end
        else
          BindingContext.AddError(JsonFieldName, ErrorMessage);
      end;
    finally
      ValidationContext.Free;
    end;
  end;
end;

function TDtoBinder.TryParseJsonValue(
  const JsonValue: TJSONValue;
  const TargetType: TRttiType;
  const PropertyPath: string;
  var BindingContext: TDtoBindingContext;
  out ParsedValue: TValue;
  out ErrorMessage: string
): Boolean;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  ErrorMessage := '';

  if JsonValue = nil then
  begin
    ErrorMessage := 'is required';
    Exit;
  end;

  if TargetType = nil then
  begin
    ErrorMessage := 'has unsupported target type';
    Exit;
  end;

  case TargetType.TypeKind of
    tkClass:
      begin
        if not (JsonValue is TJSONObject) then
        begin
          ErrorMessage := 'must be a JSON object';
          Exit;
        end;

        Exit(TryParseJsonObject(
          TJSONObject(JsonValue),
          TargetType,
          PropertyPath,
          BindingContext,
          ParsedValue,
          ErrorMessage
        ));
      end;

    tkDynArray:
      begin
        if not (JsonValue is TJSONArray) then
        begin
          ErrorMessage := 'must be a JSON array';
          Exit;
        end;

        Exit(TryParseJsonArray(
          TJSONArray(JsonValue),
          TargetType,
          PropertyPath,
          BindingContext,
          ParsedValue,
          ErrorMessage
        ));
      end;

    tkString, tkLString, tkWString, tkUString,
    tkInteger, tkInt64, tkFloat, tkEnumeration:
      begin
        Exit(TryParseScalarJsonValue(
          JsonValue,
          TargetType,
          PropertyPath,
          ParsedValue,
          ErrorMessage
        ));
      end;
  end;

  ErrorMessage := 'has an unsupported type for strict binding';
end;

function TDtoBinder.TryParseScalarJsonValue(
  const JsonValue: TJSONValue;
  const TargetType: TRttiType;
  const PropertyPath: string;
  out ParsedValue: TValue;
  out ErrorMessage: string
): Boolean;
var
  NumericText: string;
  IntegerValue: Integer;
  Int64Value: Int64;
  EnumValue: Integer;
  FormatSettings: TFormatSettings;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  ErrorMessage := '';

  if JsonValue = nil then
  begin
    ErrorMessage := 'is required';
    Exit;
  end;

  if TargetType = nil then
  begin
    ErrorMessage := 'has unsupported target type';
    Exit;
  end;

  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';

  case TargetType.TypeKind of
    tkString, tkLString, tkWString, tkUString:
      begin
        if not (JsonValue is TJSONString) then
        begin
          ErrorMessage := 'must be a string';
          Exit;
        end;

        ParsedValue := TValue.From<string>(JsonValue.Value);
        Exit(True);
      end;

    tkInteger:
      begin
        if not (JsonValue is TJSONNumber) then
        begin
          ErrorMessage := 'must be an integer';
          Exit;
        end;

        if not TryStrToInt(JsonValue.Value, IntegerValue) then
        begin
          ErrorMessage := 'must be a valid integer';
          Exit;
        end;

        ParsedValue := TValue.From<Integer>(IntegerValue);
        Exit(True);
      end;

    tkInt64:
      begin
        if not (JsonValue is TJSONNumber) then
        begin
          ErrorMessage := 'must be an int64';
          Exit;
        end;

        if not TryStrToInt64(JsonValue.Value, Int64Value) then
        begin
          ErrorMessage := 'must be a valid int64';
          Exit;
        end;

        ParsedValue := TValue.From<Int64>(Int64Value);
        Exit(True);
      end;

    tkFloat:
      begin
        if not (JsonValue is TJSONNumber) then
        begin
          ErrorMessage := 'must be a number';
          Exit;
        end;

        NumericText := JsonValue.Value;

        if TargetType.Handle = TypeInfo(Currency) then
        begin
          var CurrencyValue: Currency;

          if not TryStrToCurr(NumericText, CurrencyValue, FormatSettings) then
          begin
            ErrorMessage := 'must be a valid currency';
            Exit;
          end;

          ParsedValue := TValue.From<Currency>(CurrencyValue);
          Exit(True);
        end;

        var FloatValue: Double;

        if not TryStrToFloat(NumericText, FloatValue, FormatSettings) then
        begin
          ErrorMessage := 'must be a valid number';
          Exit;
        end;

        if TargetType.Handle = TypeInfo(Double) then
          ParsedValue := TValue.From<Double>(FloatValue)
        else if TargetType.Handle = TypeInfo(Single) then
          ParsedValue := TValue.From<Single>(FloatValue)
        else if TargetType.Handle = TypeInfo(Extended) then
          ParsedValue := TValue.From<Extended>(FloatValue)
        else
          ParsedValue := TValue.From<Double>(FloatValue);

        Exit(True);
      end;

    tkEnumeration:
      begin
        if TargetType.Handle = TypeInfo(Boolean) then
        begin
          if JsonValue is TJSONBool then
          begin
            ParsedValue := TValue.From<Boolean>(SameText(JsonValue.Value, 'true'));
            Exit(True);
          end;

          ErrorMessage := 'must be a boolean';
          Exit;
        end;

        if not (JsonValue is TJSONString) then
        begin
          ErrorMessage := 'must be a string enum value';
          Exit;
        end;

        EnumValue := GetEnumValue(TargetType.Handle, JsonValue.Value);

        if EnumValue < 0 then
        begin
          ErrorMessage := 'has an invalid enum value';
          Exit;
        end;

        ParsedValue := TValue.FromOrdinal(TargetType.Handle, EnumValue);
        Exit(True);
      end;
  end;

  ErrorMessage := 'has unsupported scalar type';
end;

function TDtoBinder.TryParseJsonObject(
  const JsonObject: TJSONObject;
  const TargetType: TRttiType;
  const PropertyPath: string;
  var BindingContext: TDtoBindingContext;
  out ParsedValue: TValue;
  out ErrorMessage: string
): Boolean;
var
  InstanceType: TRttiInstanceType;
  NestedInstance: TObject;
  ErrorCountBeforeBind: Integer;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  ErrorMessage := '';

  if not (TargetType is TRttiInstanceType) then
  begin
    ErrorMessage := 'must be a class type';
    Exit;
  end;

  InstanceType := TRttiInstanceType(TargetType);
  NestedInstance := InstanceType.MetaclassType.Create;

  try
    ErrorCountBeforeBind := BindingContext.ErrorCount;

    BindObject(
      JsonObject,
      NestedInstance,
      BindingContext
    );

    if BindingContext.ErrorCount > ErrorCountBeforeBind then
    begin
      NestedInstance.Free;
      Exit(True);
    end;

    ParsedValue := NestedInstance;
    Result := True;
  except
    NestedInstance.Free;
    raise;
  end;
end;

function TDtoBinder.TryParseJsonArray(
  const JsonArray: TJSONArray;
  const TargetType: TRttiType;
  const PropertyPath: string;
  var BindingContext: TDtoBindingContext;
  out ParsedValue: TValue;
  out ErrorMessage: string
): Boolean;
var
  DynamicArrayType: TRttiDynamicArrayType;
  ElementType: TRttiType;
  ElementValues: TArray<TValue>;
  ElementJson: TJSONValue;
  ElementValue: TValue;
  ElementErrorMessage: string;
  ElementPath: string;
  ErrorCountBeforeParse: Integer;
begin
  Result := False;
  ParsedValue := TValue.Empty;
  ErrorMessage := '';

  if not (TargetType is TRttiDynamicArrayType) then
  begin
    ErrorMessage := 'is not a dynamic array type';
    Exit;
  end;

  DynamicArrayType := TRttiDynamicArrayType(TargetType);
  ElementType := DynamicArrayType.ElementType;

  SetLength(ElementValues, JsonArray.Count);

  ErrorCountBeforeParse := BindingContext.ErrorCount;

  for var Index := 0 to JsonArray.Count - 1 do
  begin
    ElementJson := JsonArray.Items[Index];
    ElementPath := Format('%s[%d]', [PropertyPath, Index]);

    if TryParseJsonValue(
      ElementJson,
      ElementType,
      ElementPath,
      BindingContext,
      ElementValue,
      ElementErrorMessage
    ) then
    begin
      if not ElementValue.IsEmpty then
        ElementValues[Index] := ElementValue;
    end
    else
      BindingContext.AddError(ElementPath, ElementErrorMessage);
  end;

  if BindingContext.ErrorCount > ErrorCountBeforeParse then
    Exit(True);

  ParsedValue := TValue.FromArray(TargetType.Handle, ElementValues);
  Result := True;
end;

procedure TDtoBinder.ParseDto(
  const RawBody: string;
  const DtoClass: TClass;
  out Dto: TObject
);
var
  RootValue: TJSONValue;
  RootObject: TJSONObject;
  BindingContext: TDtoBindingContext;
begin
  Dto := nil;

  if DtoClass = nil then
    raise EMissingDependencyException.Create('DTO class is required.');

  if RawBody.Trim.IsEmpty then
    raise EInvalidAttributeException.Create('body must be a JSON object');

  RootValue := nil;
  BindingContext := TDtoBindingContext.Create;

  try
    RootValue := TJSONObject.ParseJSONValue(RawBody);

    if (RootValue = nil) or not (RootValue is TJSONObject) then
      raise EBinderException.Create('body must be a JSON object');

    RootObject := TJSONObject(RootValue);

    Dto := DtoClass.Create;

    try
      BindObject(
        RootObject,
        Dto,
        BindingContext
      );

      BindingContext.RaiseIfHasErrors;
    except
      Dto.Free;
      Dto := nil;
      raise;
    end;
  finally
    RootValue.Free;
    BindingContext.Release;
  end;
end;

function TDtoBinder.ParseDto<T>(const RawBody: string): T;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  InstanceType: TRttiInstanceType;
  Dto: TObject;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(TypeInfo(T));

  if not (RttiType is TRttiInstanceType) then
    raise EInvalidAttributeException.Create('Generic type must be a class');

  InstanceType := TRttiInstanceType(RttiType);

  ParseDto(RawBody, InstanceType.MetaclassType, Dto);
  Result := Dto as T;
end;

end.
