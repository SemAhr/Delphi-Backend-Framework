unit Http.ParameterBinder.Contract;

interface

uses
  System.Rtti,
  Http.Context,
  Http.ParameterDescriptor;

type
  IParameterBinder = interface
    ['{3E853950-B8ED-44F4-BA61-5EE21066128D}']
    function Bind(
      const Context: THttpContext;
      const Descriptor: TParameterDescriptor
    ): TValue;
  end;

implementation

end.
