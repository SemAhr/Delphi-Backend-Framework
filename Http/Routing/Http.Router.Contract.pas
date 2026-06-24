unit Http.Router.Contract;

interface

uses
  Http.Core;

type
  IRouter = interface
    ['{fba41ba9-ead0-46e2-b292-6a7a3ded2b56}']

    function Dispatch(const ARequest: THttpRequest): THttpResponse;
  end;

implementation

end.
