unit Http.BodyBinder.Contract;

interface

uses
  System.Rtti;

type
  IHttpBodyBinder = interface
    ['{D0B4D8CB-09A7-4C72-81A6-5BE4D8E2F001}']
    
    function Execute(const ARawBody: string; const ATargetType: TRttiType): TValue;
  end;

implementation

end.
