unit Http.Composition;

interface

uses
  System.Generics.Collections,
  Container.App,
  Http.RouteDescriptor,
  Http.Router.Port,
  Http.Server;

type
  THttpComposition = class sealed
  public
    class function CreateDefaultRouter(const ARoutes: TObjectList<TRouteDescriptor>; const AContainer: TAppContainer): IRouter; static;

    class function CreateDefaultServer(
      const APort: Integer;
      const ARoutes: TObjectList<TRouteDescriptor>;
      const AContainer: TAppContainer
    ): THttpServer; overload; static;

    class function CreateDefaultServer(
      const APort: Integer;
      const AContainer: TAppContainer
    ): THttpServer; overload; static;
  end;

implementation

uses
  System.SysUtils,
  AppExceptions,
  Dto.Binder,
  Dto.Binder.Port,
  Http.ActionInvoker,
  Http.ActionInvoker.Port,
  Http.ControllerScanner,
  Http.Router,
  Http.BodyBinder,
  Http.BodyBinder.Port,
  Http.ParameterBinder,
  Http.ParameterBinder.Port;

class function THttpComposition.CreateDefaultRouter(const ARoutes: TObjectList<TRouteDescriptor>; const AContainer: TAppContainer): IRouter;
begin
  var DtoBinder := TDtoBinder.Create;
  var BodyBinder := TBodyBinder.Create(DtoBinder);
  var ParameterBinder := TParameterBinder.Create(BodyBinder);

  var ActionInvoker := TActionInvoker.Create(AContainer, ParameterBinder);

  Result := TRouter.Create(ARoutes, ActionInvoker, AContainer);
end;

class function THttpComposition.CreateDefaultServer(
  const APort: Integer;
  const ARoutes: TObjectList<TRouteDescriptor>;
  const AContainer: TAppContainer
): THttpServer;
begin
  Result := THttpServer.Create(
    APort,
    THttpComposition.CreateDefaultRouter(ARoutes, AContainer)
  );
end;

class function THttpComposition.CreateDefaultServer(
  const APort: Integer;
  const AContainer: TAppContainer
): THttpServer;
var
  Scanner: TControllerScanner;
  Routes: TObjectList<TRouteDescriptor>;
begin
  if AContainer = nil then
    raise EMissingDependencyException.Create('Container is required.');

  Scanner := TControllerScanner.Create;
  try
    Routes := Scanner.Execute(AContainer.GetControllerTypes);

    Writeln('HTTP Routes:');
    for var Route in Routes do
      Writeln(Format(
        '%s  %-5s %s %s %s',
        [#27'[32m', Route.Method, #27'[36m', Route.Path, #27'[0m']
      ));
  finally
    Scanner.Free;
  end;

  try
    Result := THttpComposition.CreateDefaultServer(APort, Routes, AContainer);
  except
    Routes.Free;
    raise;
  end;
end;

end.
