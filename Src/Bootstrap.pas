unit Bootstrap;

interface

type
  TBootstrap = class sealed
  public
    /// <summary>
    /// Initializes the application by registering dependencies and configuring the HTTP framework.
    /// </summary>
    class procedure Create;
  end;

implementation

uses
  System.SysUtils,
  Container.App,
  Http.Composition,
  Http.Server,
  Logger.Port,
  Logger,
  Root.Controller,
  Utils.Controller,
  SignIn.UseCase.Port,
  ActivateReport.UseCase.Port,
  DeactivateReport.UseCase.Port,
  SignIn.UseCase,
  ActivateReport.UseCase,
  DeactivateReport.UseCase;

class procedure TBootstrap.Create;
const
  DefaultHttpPort = 4000;
var
  App: TAppContainer;
  Server: THttpServer;
begin
  App := TAppContainer.Create;
  Server := nil;

  try
    App.AddControllers([
      TRootController,
      TUtilsController
    ]);

    App.AddSingleton<ILogger, TLogger>;

    App.AddScoped<ISignInUseCase, TSignInUseCase>;
    App.AddScoped<IActivateReportUseCase, TActivateReportUseCase>;
    App.AddScoped<IDeactivateReportUseCase, TDeactivateReportUseCase>;

    Server := THttpComposition.CreateDefaultServer(DefaultHttpPort, App);
    Server.Start;

    Writeln(Format('HTTP server listening on port %d.', [DefaultHttpPort]));
    Writeln('Press Enter to stop...');
    Readln;
  finally
    Server.Free;
    App.Free;
  end;
end;

end.
