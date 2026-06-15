unit Http.Composition;

interface

uses
  System.Generics.Collections,
  Shared.Container.Contract,
  Http.RouteDescriptor,
  Http.Router.Contract,
  Http.Server;

type
  THttpComposition = class sealed
  public
    class function CreateDefaultRouter(
      const Routes: TObjectList<TRouteDescriptor>;
      const Container: IContainer
    ): IHttpRouter; static;

    class function CreateDefaultServer(
      const Port: Integer;
      const Routes: TObjectList<TRouteDescriptor>;
      const Container: IContainer
    ): TSimpleHttpServer; static;
  end;

implementation

uses
  Dto.Binder,
  Dto.Binder.Contract,
  Http.ActionInvoker,
  Http.ActionInvoker.Contract,
  Http.AttributeRouter,
  Http.BodyBinder.Contract,
  Http.JsonBodyBinder,
  Http.ParameterBinder,
  Http.ParameterBinder.Contract;

class function THttpComposition.CreateDefaultRouter(
  const Routes: TObjectList<TRouteDescriptor>;
  const Container: IContainer
): IHttpRouter;
var
  DtoBinder: IDtoBinder;
  BodyBinder: IHttpBodyBinder;
  ParameterBinder: IParameterBinder;
  ActionInvoker: IControllerActionInvoker;
begin
  DtoBinder := TDtoBinder.Create;
  BodyBinder := TJsonBodyBinder.Create(DtoBinder);
  ParameterBinder := TParameterBinder.Create(BodyBinder);
  ActionInvoker := TControllerActionInvoker.Create(Container, ParameterBinder);

  Result := TAttributeRouter.Create(Routes, ActionInvoker);
end;

class function THttpComposition.CreateDefaultServer(
  const Port: Integer;
  const Routes: TObjectList<TRouteDescriptor>;
  const Container: IContainer
): TSimpleHttpServer;
begin
  Result := TSimpleHttpServer.Create(
    Port,
    CreateDefaultRouter(Routes, Container)
  );
end;

end.
