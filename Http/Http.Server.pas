unit Http.Server;

interface

uses
  System.SysUtils,
  IdHTTPServer,
  IdContext,
  IdCustomHTTPServer,
  Http.Core,
  Http.Router.Port;

type
  THttpServer = class
  private
    FServer: TIdHTTPServer;
    FRouter: IRouter;

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
    AResponse.StatusCode,
    200
  );

  AResponseInfo.ResponseNo := StatusCode;
  AResponseInfo.ContentType := ContentType;
  AResponseInfo.ContentText := AResponse.Body;
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
      on E: Exception do
      begin
//        Response := TResponse.Json(
//          Format(
//            '{"error":"Internal server error","detail":"%s"}',
//            [StringReplace(E.Message, '"', '\"', [rfReplaceAll])]
//          ),
//          500
//        );
      end;
    end;

    WriteResponse(Response, AResponseInfo);
  finally
    Response.Free;
    Request.Free;
  end;
end;

end.
