unit Bootstrap;

interface

type
  TBootstrap = class sealed
  public
    class procedure Create;
  end;

implementation

uses
  Container.Port;

class procedure TBootstrap.Create;
begin
  var AppContainer: IContainer;
end;

end.
