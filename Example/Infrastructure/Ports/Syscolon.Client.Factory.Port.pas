unit Syscolon.Client.Factory.Port;

interface

uses
  UClienteKbm;

type
  ISyscolonClientFactory = interface
    ['{d50b40d5-b5ca-46e7-98f3-646eb3f845fa}']

    function CreateClient: TClienteKbm;
  end;

implementation

end.

