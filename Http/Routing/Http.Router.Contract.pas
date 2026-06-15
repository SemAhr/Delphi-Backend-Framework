unit Http.Router.Contract;

interface

uses
  Http.Core;

type
  IHttpRouter = interface
    ['{4B60B6AA-1E8E-4338-AF32-B069E7F52A86}']
    function Dispatch(const Request: THttpRequest): THttpResponse;
  end;

implementation

end.
