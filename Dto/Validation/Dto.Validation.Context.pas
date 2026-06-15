unit Dto.Validation.Context;

interface

uses
  System.Rtti,
  System.JSON;

type
  TDtoValidationContext = class
  private
    FPropertyInfo: TRttiProperty;
    FJsonFieldName: string;
    FJsonValue: TJSONValue;
  public
    constructor Create(
      const PropertyInfo: TRttiProperty;
      const JsonFieldName: string;
      const JsonValue: TJSONValue
    );

    property PropertyInfo: TRttiProperty read FPropertyInfo;
    property JsonFieldName: string read FJsonFieldName;
    property JsonValue: TJSONValue read FJsonValue;
  end;

implementation

constructor TDtoValidationContext.Create(
  const PropertyInfo: TRttiProperty;
  const JsonFieldName: string;
  const JsonValue: TJSONValue
);
begin
  inherited Create;

  FPropertyInfo := PropertyInfo;
  FJsonFieldName := JsonFieldName;
  FJsonValue := JsonValue;
end;

end.
