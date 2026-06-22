unit Http.BodyBinder;

interface

uses
  System.Rtti,
  Http.BodyBinder.Contract,
  Dto.Binder.Contract;

type
  TBodyBinder = class(TInterfacedObject, IHttpBodyBinder)
  private
    FDtoBinder: IDtoBinder;
public
    constructor Create(const ADtoBinder: IDtoBinder);
function Execute(const ARawBody: string; const ATargetType: TRttiType): TValue;
end;

implementation

uses
  AppExceptions;
constructor TBodyBinder.Create(const ADtoBinder: IDtoBinder);
begin
  inherited Create;

  if ADtoBinder = nil then
    raise EMissingDependencyException.Create('DTO binder is required.');

  FDtoBinder := ADtoBinder;
end;
function TBodyBinder.Execute(const ARawBody: string; const ATargetType: TRttiType) : TValue;
var
  Dto: TObject;
begin
  if not (ATargetType is TRttiInstanceType) then
    raise EBinderException.Create('Body parameter must be a class DTO.');

  FDtoBinder.ParseDto(
    ARawBody,
    TRttiInstanceType(ATargetType).MetaclassType,
    Dto
  );

  TValue.Make(@Dto, ATargetType.Handle, Result);
end;
end.
