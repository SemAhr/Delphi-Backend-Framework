unit SignIn.UseCase.Port;

interface

uses
  SignIn.Request.Dto,
  SignIn.Response.Dto;

type
  ISignInUseCase = interface
    ['{1af70909-4c5f-4883-b5ca-2577dd6cefbc}']

    function Execute(const ARequestDto: TSignInRequestDto): TSignInResponseDto;
  end;

implementation

end.
