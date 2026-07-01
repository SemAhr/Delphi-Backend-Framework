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
    [JsonName('username')]
    property Username: string read FUsername write FUsername;

    [Required]
    [JsonName('password')]
    property Password: string read FPassword write FPassword;
  end;

implementation

end.
