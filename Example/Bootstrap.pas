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
  Logger.Options,
  Pui.Options,
  Root.Controller,
  Utils.Controller,
  Logger.Port,
  Pui.Client.Port,
  SignIn.UseCase.Port,
  ActivateReport.UseCase.Port,
  DeactivateReport.UseCase.Port,
  Logger,
  Pui.Client,
  SignIn.UseCase,
  ActivateReport.UseCase,
  DeactivateReport.UseCase;

class procedure TBootstrap.Create;
var
  App: TAppContainer;
  Server: THttpServer;
begin
  App := TAppContainer.Create;
  Server := nil;

  try
    App.AddOptions<TLoggerOptions>;
    App.AddOptions<TPuiOptions>;

    App.AddControllers([
      TRootController,
      TUtilsController
    ]);

    App.AddSingleton<ILogger, TLogger>;
    App.AddSingleton<IPuiClient, TPuiClient>;

    App.AddScoped<ISignInUseCase, TSignInUseCase>;
    App.AddScoped<IActivateReportUseCase, TActivateReportUseCase>;
    App.AddScoped<IDeactivateReportUseCase, TDeactivateReportUseCase>;

    Server := THttpComposition.CreateDefaultServer(App);
    Server.Start;

    Writeln('Press Enter to stop...');
    Readln;
  finally
    Server.Free;
    App.Free;
  end;
end;

end.
