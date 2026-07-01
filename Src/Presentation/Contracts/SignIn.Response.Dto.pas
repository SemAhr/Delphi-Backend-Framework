unit SignIn.Response.Dto;

interface

uses
  Dto.Port,
  Dto.Attributes;

type
  TSignInResponseDto = class(TInterfacedObject, IDto)
  private
    FAccessToken: string;
  public
    [JsonName('token')]
    property AccessToken: string read FAccessToken write FAccessToken;
  end;

implementation

end.
