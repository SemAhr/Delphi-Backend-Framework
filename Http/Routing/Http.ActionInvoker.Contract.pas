unit Http.ActionInvoker.Contract;

interface

uses
  System.Rtti,
  Http.Context,
  Http.RouteDescriptor;

type
  IControllerActionInvoker = interface
    ['{5215D3B4-6B44-4D63-B457-51BB35A58C70}']
    function Invoke(
      const ARoute: TRouteDescriptor;
      const AContext: THttpContext
    ): TValue;
  end;

implementation

end.
