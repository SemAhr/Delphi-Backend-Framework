unit SignIn.UseCase;

interface

uses
  SignIn.UseCase.Port,
  SignIn.Request.Dto,
  SignIn.Response.Dto;

type
  TSignInUseCase = class(TInterfacedObject, ISignInUseCase)
  public
    function Execute(const RequestDto: TSignInRequestDto): TSignInResponseDto;
  end;

implementation

{ TSignInUseCase }

function TSignInUseCase.Execute(const RequestDto: TSignInRequestDto): TSignInResponseDto;
begin
  Result := TSignInResponseDto.Create;
  Result.AccessToken := 'access_token';
end;

end.
