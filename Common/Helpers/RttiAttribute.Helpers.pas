unit RttiAttribute.Helpers;

interface

uses
  System.Rtti,
  System.Generics.Collections;

type
  TRttiAttributeHelpers = class
  public
    class function HasAttribute<T: TCustomAttribute>(const RttiObject: TRttiObject): Boolean; static;
    class function TryGetAttribute<T: TCustomAttribute>(const RttiObject: TRttiObject; out AttributeValue: T): Boolean; static;
    class function GetAttributes<T: TCustomAttribute>(const RttiObject: TRttiObject): TObjectList<T>; static;
  end;

implementation

class function TRttiAttributeHelpers.HasAttribute<T>(const RttiObject: TRttiObject): Boolean;
var
  AttributeItem: TCustomAttribute;
begin
  if RttiObject = nil then
    Exit(False);

  for AttributeItem in RttiObject.GetAttributes do
    if AttributeItem is T then
      Exit(True);

  Result := False;
end;

class function TRttiAttributeHelpers.TryGetAttribute<T>(const RttiObject: TRttiObject; out AttributeValue: T): Boolean;
var
  AttributeItem: TCustomAttribute;
begin
  AttributeValue := nil;

  if RttiObject = nil then
    Exit(False);

  for AttributeItem in RttiObject.GetAttributes do
  begin
    if AttributeItem is T then
    begin
      AttributeValue := T(AttributeItem);
      Exit(True);
    end;
  end;

  Result := False;
end;

class function TRttiAttributeHelpers.GetAttributes<T>(const RttiObject: TRttiObject): TObjectList<T>;
var
  AttributeItem: TCustomAttribute;
  Values: TObjectList<T>;
begin
  if RttiObject = nil then
    Exit(nil);

  Values := TObjectList<T>.Create;
  try
    for AttributeItem in RttiObject.GetAttributes do
    begin
      if AttributeItem is T then
        Values.Add(T(AttributeItem));
    end;

    Result := Values;
  finally
    Values.Free;
  end;
end;

end.
