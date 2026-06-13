unit Http.JsonBodyBinder;

interface

uses
  System.Rtti,
  Http.BodyBinder.Contract,
  Dto.Binder;

type
  TJsonBodyBinder = class(TInterfacedObject, IHttpBodyBinder)
  private
    FDtoBinder: TDtoBinder;
  public
    constructor Create;
    destructor Destroy; override;

    function BindBody(
      const RawBody: string;
      const TargetType: TRttiType
    ): TValue;
  end;

implementation

uses
  AppExceptions;

constructor TJsonBodyBinder.Create;
begin
  inherited Create;
  FDtoBinder := TDtoBinder.Create;
end;

destructor TJsonBodyBinder.Destroy;
begin
  FDtoBinder.Free;
  inherited;
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
