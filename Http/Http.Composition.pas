unit Http.Composition;

interface

uses
  System.Generics.Collections,
  Container.Contract,
  Http.RouteDescriptor,
  Http.Router.Contract,
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
  Dto.Binder.Contract,
  Http.ActionInvoker,
  Http.ActionInvoker.Contract,
  Http.Router,
  Http.BodyBinder,
  Http.BodyBinder.Contract,
  Http.ParameterBinder,
  Http.ParameterBinder.Contract;

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
