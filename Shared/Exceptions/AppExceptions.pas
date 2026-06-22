unit AppExceptions;

interface

uses
  System.SysUtils;

type
  EAppException = class(Exception);
  EDependencyException = class(EAppException);
  EServiceException = class(EAppException);
  EMetadataException = class(EAppException);

  EMissingDependencyException = class(EDependencyException);
  EInvalidDependencyException = class(EDependencyException);

  EInfrastructureUnavailableException = class(EServiceException);
  EJwtException = class(EServiceException);
  ERefreshTokenException = class(EServiceException);
  ESignException = class(EServiceException);
  ESessionException = class(EServiceException);
  EControllerException = class(EServiceException);
  EBinderException = class(EServiceException)
  private
    function GetMessages: TArray<string>;
public
    property Messages: TArray<string> read GetMessages;
constructor Create(const AMessage: string); overload;
constructor Create(const AMessages: TArray<string>); overload;
end;

  EMissingAttributeException = class(EMetadataException);
  EInvalidAttributeException = class(EMetadataException);
  EUnexpectedAttributeException = class(EMetadataException);
  EOutOfRangeAttributeException = class(EMetadataException);
  EActionNotAssignedException = class(EMetadataException);

implementation

{ EBinderException }

constructor EBinderException.Create(const AMessage: string);
begin
  inherited Create(AMessage);
end;
constructor EBinderException.Create(const AMessages: TArray<string>);
begin
  inherited Create(string.Join(',', AMessages));
end;
function EBinderException.GetMessages: TArray<string>;
begin
  Result := Message.Split([',']);
end;
end.
