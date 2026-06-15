unit Dto.Metadata;

interface

uses
  System.Rtti,
  Dto.Attributes;

type
  TDtoMetadata = class
  public
    class function GetJsonFieldName(const PropertyInfo: TRttiProperty): string; static;
  end;

implementation

class function TDtoMetadata.GetJsonFieldName(const PropertyInfo: TRttiProperty): string;
begin
  Result := PropertyInfo.Name;

  for var AttributeItem in PropertyInfo.GetAttributes do
    if AttributeItem is JsonNameAttribute then
      Exit(JsonNameAttribute(AttributeItem).Name);
end;

end.
