unit Shared.HttpExceptions;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  EHttpException = class(Exception)
  private
    FStatusCode: Integer;
    FErrorName: string;
    FMessages: TArray<string>;
    FCause: Exception;
  public
    constructor Create(
      const StatusCode: Integer;
      const ErrorName: string;
      const MessageText: string;
      const Cause: Exception = nil
    ); overload;

    constructor Create(
      const StatusCode: Integer;
      const ErrorName: string;
      const MessageList: TArray<string>;
      const Cause: Exception = nil
    ); overload;

    property StatusCode: Integer read FStatusCode;
    property ErrorName: string read FErrorName;
    property Messages: TArray<string> read FMessages;
    property Cause: Exception read FCause;
  end;

  EBadRequestException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Bad Request'; const Cause: Exception = nil; const ErrorName: string = 'Bad Request'); overload;
    constructor Create(const Messages: TArray<string>; const Cause: Exception = nil; const ErrorName: string = 'Bad Request'); overload;
  end;

  EUnauthorizedException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Unauthorized'; const Cause: Exception = nil; const ErrorName: string = 'Unauthorized');
  end;

  EForbiddenException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Forbidden'; const Cause: Exception = nil; const ErrorName: string = 'Forbidden');
  end;

  ENotFoundException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Not Found'; const Cause: Exception = nil; const ErrorName: string = 'Not Found');
  end;

  EConflictException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Conflict'; const Cause: Exception = nil; const ErrorName: string = 'Conflict');
  end;

  EInternalServerErrorException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Internal Server Error'; const Cause: Exception = nil; const ErrorName: string = 'Internal Server Error');
  end;

  EBadGatewayException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Bad Gateway'; const Cause: Exception = nil; const ErrorName: string = 'Bad Gateway');
  end;

  EServiceUnavailableException = class(EHttpException)
  public
    constructor Create(const MessageText: string = 'Service Unavailable'; const Cause: Exception = nil; const ErrorName: string = 'Service Unavailable');
  end;

function BuildHttpExceptionJson(
  const StatusCode: Integer;
  const ErrorName: string;
  const Messages: TArray<string>
): string;

implementation

uses
  System.JSON,
  System.StrUtils ;

function BuildHttpExceptionJson(const StatusCode: Integer; const ErrorName: string; const Messages: TArray<string>): string;
var
  ResponseMessages: TArray<string>;
begin
  var JsonObject := TJSONObject.Create;
  try
    JsonObject.AddPair('error', ErrorName);
    JsonObject.AddPair('statusCode', TJSONNumber.Create(StatusCode));

    {if Config.IsProduction and (StatusCode = 500) then
      ResponseMessages := ['An error ocurred']
    else}

    ResponseMessages := Messages;

    if Length(ResponseMessages) = 1 then
    begin
      JsonObject.AddPair('message', ResponseMessages[0]);
      Exit(JsonObject.ToJSON);
    end;

    var JsonMessages := TJSONArray.Create;
    try
      for var Index := 0 to High(ResponseMessages) do
        JsonMessages.Add(ResponseMessages[Index]);

      JsonObject.AddPair('message', JsonMessages);
      JsonMessages := nil;
    finally
      JsonMessages.Free;
    end;

    Result := JsonObject.ToJSON;
  finally
    JsonObject.Free;
  end;
end;

{ EHttpException }

constructor EHttpException.Create(
  const StatusCode: Integer;
  const ErrorName: string;
  const MessageText: string;
  const Cause: Exception
);
begin
  inherited Create(MessageText);
  FStatusCode := StatusCode;
  FErrorName := ErrorName;
  FMessages := [MessageText];
  FCause := Cause;
end;

constructor EHttpException.Create(
  const StatusCode: Integer;
  const ErrorName: string;
  const MessageList: TArray<string>;
  const Cause: Exception
);
begin
  inherited Create(ErrorName);
  FStatusCode := StatusCode;
  FErrorName := ErrorName;
  FMessages := MessageList;
  FCause := Cause;
end;

{ Derived }

constructor EBadRequestException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(400, ErrorName, MessageText, Cause);
end;

constructor EBadRequestException.Create(const Messages: TArray<string>; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(400, ErrorName, Messages, Cause);
end;

constructor EUnauthorizedException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(401, ErrorName, MessageText, Cause);
end;

constructor EForbiddenException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(403, ErrorName, MessageText, Cause);
end;

constructor ENotFoundException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(404, ErrorName, MessageText, Cause);
end;

constructor EConflictException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(409, ErrorName, MessageText, Cause);
end;

constructor EInternalServerErrorException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(500, ErrorName, MessageText, Cause);
end;

constructor EBadGatewayException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(502, ErrorName, MessageText, Cause);
end;

constructor EServiceUnavailableException.Create(const MessageText: string; const Cause: Exception; const ErrorName: string);
begin
  inherited Create(503, ErrorName, MessageText, Cause);
end;

end.
