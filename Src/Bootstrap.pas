unit Bootstrap;

interface

type
  TBootstrap = class sealed
  public
    class procedure Create;
  end;

implementation

uses
  Container.Contract;

class procedure TBootstrap.Create;
begin
  var AppContainer: IContainer;
end;

end.
