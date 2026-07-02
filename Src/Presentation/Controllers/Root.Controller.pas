unit Root.Controller;

interface

uses
  Http.Controller.Port,
  Http.Attributes,
  Http.Parameter.Attributes,
  Http.Context,
  SignIn.UseCase.Port,
  ActivateReport.UseCase.Port,
  DeactivateReport.UseCase.Port,
  SignIn.Request.Dto,
  SignIn.Response.Dto,
  ActivateReport.Dto,
  DeactivateReport.Dto,
  Success.Dto;

type
  [Route('/')]
  TRootController = class(TInterfacedObject, IController)
  private
    FSignInUseCase: ISignInUseCase;
    FActivateReportUseCase: IActivateReportUseCase;
    FDeactivateReportUseCase: IDeactivateReportUseCase;
  public
    constructor Create(
      const SignInUseCase: ISignInUseCase
    );

    [Post('/login/:id')]
    [StatusCode(201)]
    function SignIn(
      [FromContext] const Context: TContext;
      [FromCookie('Cookie_1')] const Cookie1: string;
      [FromHeader('test')] const Test: string;
      [FromRoute('id')] const Id: string;
      [FromQuery('id_user')] const IdUser: string;
      [FromBody] const ARequestDto: TSignInRequestDto
    ): TSignInResponseDto;

    // protected route
    [Post('/activar-reporte')]
    [StatusCode(201)]
    function ActivateReport([FromBody] const ARequestDto: TActivateReportDto): TSuccessDto;

    // protected route
    [Post('/desactivar-reporte')]
    function DeactivateReport([FromBody] const ARequestDto: TDeactivateReportDto): TSuccessDto;

    { Testing }
    // protected route
    [Post('/activar-reporte-prueba')]
    function ActivateReportTest([FromBody] const ARequestDto: TActivateReportDto): TSuccessDto;
  end;

implementation

uses
  AppExceptions,
  HttpExceptions;

constructor TRootController.Create(
  const SignInUseCase: ISignInUseCase
);
begin
  if SignInUseCase = nil then
    raise EMissingDependencyException.Create('Sign in use case is required.');

  FSignInUseCase := SignInUseCase;
end;

function TRootController.SignIn(
  const Context: TContext;
  const Cookie1: string;
  const Test: string;
  const Id: string;
  const IdUser: string;
  const ARequestDto: TSignInRequestDto
): TSignInResponseDto;
begin
  Result := FSignInUseCase.Execute(ARequestDto);
end;

function TRootController.ActivateReport(const ARequestDto: TActivateReportDto): TSuccessDto;
begin
end;

function TRootController.DeactivateReport(const ARequestDto: TDeactivateReportDto): TSuccessDto;
begin
end;

{ Testing }

function TRootController.ActivateReportTest(const ARequestDto: TActivateReportDto): TSuccessDto;
begin
end;

end.
