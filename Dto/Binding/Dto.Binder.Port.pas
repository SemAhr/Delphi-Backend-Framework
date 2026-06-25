unit Dto.Binder.Port;

interface

type
  IDtoBinder = interface
    ['{b56972a6-a9f2-4dae-a7b4-8b1641f646c1}']
    procedure ParseDto(
      const ARawBody: string;
      const ADtoClass: TClass;
      out ADto: TObject
    );
  end;

implementation

end.
