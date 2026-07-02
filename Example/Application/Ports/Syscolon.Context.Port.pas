unit Syscolon.Context.Port;

interface

uses
  System.Variants;

type
  TSyscolonResponseProcedure = reference to procedure(const Response: string);

  ISyscolonContext = interface
    ['{837E32AF-69BE-4289-B711-2DF4D9DA9B94}']
    procedure Run(
      const Prefix: string;
      const Service: string;
      const Action: TSyscolonResponseProcedure
    ); overload;

    procedure Run(
      const Prefix: string;
      const Service: string;
      const Data: TArray<Variant>;
      const Action: TSyscolonResponseProcedure
    ); overload;

    procedure Run(
      const Prefix: string;
      const Service: string;
      const Data: TArray<Variant>;
      const Username: string;
      const Action: TSyscolonResponseProcedure
    ); overload;
  end;

implementation

end.

