unit Http.Server;

interface

uses
  System.SysUtils,
  IdHTTPServer,
  IdContext,
  IdCustomHTTPServer,
  Http.Core,
  Http.Router.Contract;

type
  THttpServer = class
  private
    FServer: TIdHTTPServer;
    FRouter: IHttpRouter;
procedure HandleCommand(
      AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );
function BuildRequest(const ARequestInfo: TIdHTTPRequestInfo): THttpRequest;
procedure WriteResponse(const AResponse: THttpResponse; const AResponseInfo: TIdHTTPResponseInfo);
public
    constructor Create(const APort: Integer; const ARouter: IHttpRouter);
destructor Destroy; override;
procedure Start;
procedure Stop;
end;

implementation

uses
  System.Classes,
  AppExceptions;
constructor THttpServer.Create(const APort: Integer; const ARouter: IHttpRouter);
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
function THttpServer.BuildRequest(const ARequestInfo: TIdHTTPRequestInfo) : THttpRequest;
begin
  Result := THttpRequest.Create;

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
procedure TSimpleHttpServer.WriteResponse(const AResponse: THttpResponse; const AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.ResponseNo := AResponse.StatusCode;
  AResponseInfo.ContentType := AResponse.ContentType;
  AResponseInfo.ContentText := AResponse.Body;
end;
procedure TSimpleHttpServer.HandleCommand(
  AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo
);
begin
  var Request: THttpRequest := nil;
var Response: THttpResponse := nil;

  try
    try
      Request := BuildRequest(ARequestInfo);
      Response := FRouter.Dispatch(Request);
    except
      on E: Exception do
      begin
        Response := THttpResponse.Json(
          Format(
            '{"error":"Internal server error","detail":"%s"}',
            [StringReplace(E.Message, '"', '\"', [rfReplaceAll])]
          ),
          500
        );
end;
end;

    WriteResponse(Response, AResponseInfo);
  finally
    Response.Free;
    Request.Free;
end;
end;
end.
