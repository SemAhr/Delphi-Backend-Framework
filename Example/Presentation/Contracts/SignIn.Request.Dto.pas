unit SignIn.Request.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TSignInRequestDto = class(TInterfacedObject, IDto)
  private
    FUsername: string;
    FPassword: string;
  public
    [Required]
    [Length(3)]
    [JsonName('usuario')]
    property Username: string read FUsername write FUsername;

    [Required]
    [Length(16, 20)]
    [JsonName('clave')]
    property Password: string read FPassword write FPassword;
  end;

implementation

end.
