unit Dto.TypeInspector;

interface

uses
  System.Rtti,
  System.TypInfo;

type
  TDtoTypeInspector = class
  public
    class function IsStringType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsBooleanType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsIntegerType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsInt64Type(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsCurrencyType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsDateOnlyType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsDateLikeType(const PropertyInfo: TRttiProperty): Boolean; static;
    class function IsNumericType(const PropertyInfo: TRttiProperty): Boolean; static;

    class function GetDateTypeMessage(const PropertyInfo: TRttiProperty): string; static;
  end;

implementation

uses
  System.SysUtils,
  Shared.RttiAttribute.Helpers,
  Dto.Attributes;

class function TDtoTypeInspector.IsStringType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result := PropertyInfo.PropertyType.TypeKind in [
    tkString,
    tkLString,
    tkWString,
    tkUString
  ];
end;

class function TDtoTypeInspector.IsBooleanType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result :=
    (PropertyInfo.PropertyType.TypeKind = tkEnumeration) and
    (PropertyInfo.PropertyType.Handle = TypeInfo(Boolean));
end;

class function TDtoTypeInspector.IsIntegerType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result := PropertyInfo.PropertyType.TypeKind = tkInteger;
end;

class function TDtoTypeInspector.IsInt64Type(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result := PropertyInfo.PropertyType.TypeKind = tkInt64;
end;

class function TDtoTypeInspector.IsCurrencyType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result := PropertyInfo.PropertyType.Handle = TypeInfo(Currency);
end;

class function TDtoTypeInspector.IsDateOnlyType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result :=
    TRttiAttributeHelpers.HasAttribute<IsDateAttribute>(PropertyInfo) or
    (PropertyInfo.PropertyType.Handle = TypeInfo(TDate));
end;

class function TDtoTypeInspector.IsDateLikeType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result :=
    (PropertyInfo.PropertyType.TypeKind = tkFloat) and
    (
      TRttiAttributeHelpers.HasAttribute<IsDateAttribute>(PropertyInfo) or
      TRttiAttributeHelpers.HasAttribute<IsDateTimeAttribute>(PropertyInfo) or
      (PropertyInfo.PropertyType.Handle = TypeInfo(TDate)) or
      (PropertyInfo.PropertyType.Handle = TypeInfo(TTime)) or
      (PropertyInfo.PropertyType.Handle = TypeInfo(TDateTime))
    );
end;

class function TDtoTypeInspector.IsNumericType(
  const PropertyInfo: TRttiProperty
): Boolean;
begin
  Result :=
    IsIntegerType(PropertyInfo) or
    IsInt64Type(PropertyInfo) or
    IsCurrencyType(PropertyInfo) or
    (
      (PropertyInfo.PropertyType.TypeKind = tkFloat) and
      not IsDateLikeType(PropertyInfo)
    );
end;

class function TDtoTypeInspector.GetDateTypeMessage(
  const PropertyInfo: TRttiProperty
): string;
begin
  if IsDateOnlyType(PropertyInfo) then
    Exit('must be a date');

  Result := 'must be a datetime';
end;

end.
