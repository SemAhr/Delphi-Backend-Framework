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
  Container.App;

class procedure TBootstrap.Create;
begin
  var AppContainer := TAppContainer.Create;
  try
    // Register dependencies and HTTP framework components here.
  finally
    AppContainer.Free;
  end;
end;

end.
