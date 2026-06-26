unit Http.Server;

interface

uses
  System.SysUtils,
  IdHTTPServer,
  IdContext,
  IdCustomHTTPServer,
  Http.Core,
  Http.Router.Port,
  Error.Dto;

type
  THttpServer = class
  private
    FServer: TIdHTTPServer;
    FRouter: IRouter;

    function HandleError(const Error: string; const Messages: TArray<string>): string;

    procedure HandleCommand(
      AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );

    function BuildRequest(const ARequestInfo: TIdHTTPRequestInfo): TRequest;

    procedure WriteResponse(const AResponse: TResponse; const AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create(const APort: Integer; const ARouter: IRouter);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.Math,
  HttpExceptions,
  AppExceptions,
  Json.Helpers;

constructor THttpServer.Create(const APort: Integer; const ARouter: IRouter);
begin
  inherited Create;

  if ARouter = nil then
    raise EMissingDependencyException.Create('Router is required.');

  FRouter := ARouter;

  FServer := TIdHTTPServer.Create(nil);
  FServer.DefaultPort := APort;
  FServer.OnCommandGet := HandleCommand;
  FServer.OnCommandOther := HandleCommand;
end;

destructor THttpServer.Destroy;
begin
  Stop;
  FServer.Free;
  FRouter := nil;

  inherited;
end;

procedure THttpServer.Start;
begin
  FServer.Active := True;
end;

procedure THttpServer.Stop;
begin
  if FServer.Active then
    FServer.Active := False;
end;

function THttpServer.BuildRequest(const ARequestInfo: TIdHTTPRequestInfo): TRequest;
begin
  Result := TRequest.Create;

  Result.Method := UpperCase(ARequestInfo.Command);
  Result.Path := ARequestInfo.Document;

  for var I := 0 to ARequestInfo.RawHeaders.Count - 1 do
  begin
    var Name := ARequestInfo.RawHeaders.Names[I];

    if Name <> '' then
      Result.Headers.AddOrSetValue(
        LowerCase(Name),
        ARequestInfo.RawHeaders.ValueFromIndex[I]
      );
  end;

  for var I := 0 to ARequestInfo.Params.Count - 1 do
  begin
    var Name := ARequestInfo.Params.Names[I];

    if Name <> '' then
      Result.QueryParams.AddOrSetValue(
        Name,
        ARequestInfo.Params.ValueFromIndex[I]
      );
  end;

  if Assigned(ARequestInfo.PostStream) then
  begin
    ARequestInfo.PostStream.Position := 0;

    with TStringStream.Create('', TEncoding.UTF8) do
    try
      CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size);
      Result.Body := DataString;
    finally
      Free;
    end;
  end;
end;

procedure THttpServer.WriteResponse(const AResponse: TResponse; const AResponseInfo: TIdHTTPResponseInfo);
begin
  var ContentType := IfThen(
    AResponse.ContentType.Trim.IsEmpty,
    'application/json; charset=utf-8',
    AResponse.ContentType
  );

  var StatusCode := IfThen(
    AResponse.StatusCode <= 0,
    200,
    AResponse.StatusCode
  );

  AResponseInfo.ResponseNo := StatusCode;
  AResponseInfo.ContentType := ContentType;
  AResponseInfo.ContentText := AResponse.Body;
end;

function THttpServer.HandleError(const Error: string; const Messages: TArray<string>): string;
begin
  var Response := TErrorDto.Create;
  Response.Error := Error;
  Response.Messages := Messages;

  Result := TJsonHelpers.ToString(Response);
end;

procedure THttpServer.HandleCommand(
  AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo
);
var
  Request: TRequest;
  Response: TResponse;
begin
  Request := nil;
  Response := nil;

  try
    try
      Request := BuildRequest(ARequestInfo);
      Response := FRouter.Dispatch(Request);
    except
      on Error: EHttpException do
      begin
        Response.StatusCode := Error.StatusCode;
        Response.Body := HandleError(Error.ErrorName, Error.Messages);
      end;

      on Error: Exception do
      begin
        Response.StatusCode := 500;
        Response.Body := HandleError('Internal Server Error', [Error.Message]);
      end;
    end;

    WriteResponse(Response, AResponseInfo);
  finally
    Response.Free;
    Request.Free;
  end;
end;

end.
