unit Common.Container.Contract;

interface

uses
  System.TypInfo;

type
  IContainer = interface
    ['{9C7D88CE-44DB-43E6-A89A-6D4BDBA52DA3}']

    function Resolve(ATypeInfo: PTypeInfo): TObject;
  end;

implementation

end.
