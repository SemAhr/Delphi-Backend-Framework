unit Clabe.Helpers;

interface

type
  TClabeHelpers = class
    class function Validate(const Clabe: string): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

class function TClabeHelpers.Validate(const Clabe: string): TArray<string>;
var
  Errors: TList<string>;
  Index: Integer;
begin
  Errors := TList<string>.Create;
  try
    if Length(Clabe) <> 18 then
      Errors.Add('clabe length must be 18');

    if not Clabe.StartsWith('680') then
      Errors.Add('clabe is invalid');

    for Index := 1 to Length(Clabe) do
    begin
      if not CharInSet(Clabe[Index], ['0'..'9']) then
      begin
        Errors.Add('clabe must contain only digits');
        Break;
      end;
    end;

    Result := Errors.ToArray;
  finally
    Errors.Free;
  end;
end;

end.
