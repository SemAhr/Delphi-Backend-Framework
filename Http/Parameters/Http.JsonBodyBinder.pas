unit Http.JsonBodyBinder;

interface

uses
  System.Rtti,
  Http.BodyBinder.Contract,
  Dto.Binder.Contract;

type
  TJsonBodyBinder = class(TInterfacedObject, IHttpBodyBinder)
  private
    FDtoBinder: IDtoBinder;
  public
    constructor Create(const ADtoBinder: IDtoBinder);

    function BindBody(
      const RawBody: string;
      const TargetType: TRttiType
    ): TValue;
  end;

implementation

uses
  Shared.AppExceptions;

constructor TJsonBodyBinder.Create(const ADtoBinder: IDtoBinder);
begin
  inherited Create;

  if ADtoBinder = nil then
    raise EMissingDependencyException.Create('DTO binder is required.');

  FDtoBinder := ADtoBinder;
end;

function TJsonBodyBinder.BindBody(
  const RawBody: string;
  const TargetType: TRttiType
): TValue;
var
  Dto: TObject;
begin
  if not (TargetType is TRttiInstanceType) then
    raise EBinderException.Create('Body parameter must be a class DTO.');

  FDtoBinder.ParseDto(
    RawBody,
    TRttiInstanceType(TargetType).MetaclassType,
    Dto
  );

  TValue.Make(@Dto, TargetType.Handle, Result);
end;

end.
