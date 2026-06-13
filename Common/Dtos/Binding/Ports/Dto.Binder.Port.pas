unit Dto.Binder.Port;

interface

type
  IDtoBinder = interface
    ['{59768F01-7C77-4666-90AE-7447C8D23E78}']
    procedure ParseDto(
      const RawBody: string;
      const DtoClass: TClass;
      out Dto: TObject
    );
  end;

implementation

end.
