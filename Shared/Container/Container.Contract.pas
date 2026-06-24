unit Container.Contract;

interface

uses
  System.TypInfo;

type
  IContainer = interface
    ['{c5946003-6eda-4cbd-974f-49b3984624b0}']

    function Resolve(const ATypeInfo: PTypeInfo): TObject;
  end;

implementation

end.
