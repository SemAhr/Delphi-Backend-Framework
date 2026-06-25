unit Http.ActionInvoker.Port;

interface

uses
  System.Rtti,
  Http.Context,
  Http.RouteDescriptor;

type
  IActionInvoker = interface
    ['{1c23c272-a91e-4f62-8a0e-dbd4eff74c5a}']

    function Execute(const ARoute: TRouteDescriptor; const AContext: THttpContext): TValue;
  end;

implementation

end.
