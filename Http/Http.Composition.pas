unit Http.Composition;

interface

uses
  System.Generics.Collections,
  Container.Port,
  Http.RouteDescriptor,
  Http.Router.Port,
  Http.Server;

type
  THttpComposition = class sealed
  public
    class function CreateDefaultRouter(const ARoutes: TObjectList<TRouteDescriptor>; const AContainer: IContainer): IRouter; static;

    class function CreateDefaultServer(
      const APort: Integer;
      const ARoutes: TObjectList<TRouteDescriptor>;
      const AContainer: IContainer
    ): THttpServer; static;
  end;

implementation

uses
  Dto.Binder,
  Dto.Binder.Port,
  Http.ActionInvoker,
  Http.ActionInvoker.Port,
  Http.Router,
  Http.BodyBinder,
  Http.BodyBinder.Port,
  Http.ParameterBinder,
  Http.ParameterBinder.Port;

class function THttpComposition.CreateDefaultRouter(const ARoutes: TObjectList<TRouteDescriptor>; const AContainer: IContainer): IRouter;
begin
  var DtoBinder := TDtoBinder.Create;
  var BodyBinder := TBodyBinder.Create(DtoBinder);
  var ParameterBinder := TParameterBinder.Create(BodyBinder);

  var ActionInvoker := TActionInvoker.Create(AContainer, ParameterBinder);

  Result := TRouter.Create(ARoutes, ActionInvoker);
end;

class function THttpComposition.CreateDefaultServer(
  const APort: Integer;
  const ARoutes: TObjectList<TRouteDescriptor>;
  const AContainer: IContainer
): THttpServer;
begin
  Result := THttpServer.Create(
    APort,
    THttpComposition.CreateDefaultRouter(ARoutes, AContainer)
  );
end;

end.
