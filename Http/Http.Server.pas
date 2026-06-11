unit Http.Server;

interface

uses
  System.SysUtils,
  IdHTTPServer,
  IdContext,
  IdCustomHTTPServer,
  Http.Core,
  Http.AttributeRouter;

type
  TSimpleHttpServer = class
  private
    FServer: TIdHTTPServer;
    FRouter: TAttributeRouter;

    procedure HandleCommand(
      AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo
    );

    function BuildRequest(ARequestInfo: TIdHTTPRequestInfo): THttpRequest;

    procedure WriteResponse(
      const Response: THttpResponse;
      AResponseInfo: TIdHTTPResponseInfo
    );

  public
    constructor Create(
      const APort: Integer;
      const ARouter: TAttributeRouter
    );

    destructor Destroy; override;

    procedure Start;
    procedure Stop;
  end;

implementation

uses
  System.Classes;

constructor TSimpleHttpServer.Create(
  const APort: Integer;
  const ARouter: TAttributeRouter
);
begin
  inherited Create;

  FRouter := ARouter;

  FServer := TIdHTTPServer.Create(nil);
  FServer.DefaultPort := APort;
  FServer.OnCommandGet := HandleCommand;
  FServer.OnCommandOther := HandleCommand;
end;

destructor TSimpleHttpServer.Destroy;
begin
  Stop;
  FServer.Free;
  FRouter.Free;

  inherited;
end;

procedure TSimpleHttpServer.Start;
begin
  FServer.Active := True;
end;

procedure TSimpleHttpServer.Stop;
begin
  if FServer.Active then
    FServer.Active := False;
end;

function TSimpleHttpServer.BuildRequest(
  ARequestInfo: TIdHTTPRequestInfo
): THttpRequest;
var
  I: Integer;
  Name: string;
begin
  Result := THttpRequest.Create;

  Result.Method := UpperCase(ARequestInfo.Command);
  Result.Path := ARequestInfo.Document;

  for I := 0 to ARequestInfo.RawHeaders.Count - 1 do
  begin
    Name := ARequestInfo.RawHeaders.Names[I];

    if Name <> '' then
      Result.Headers.AddOrSetValue(
        LowerCase(Name),
        ARequestInfo.RawHeaders.ValueFromIndex[I]
      );
  end;

  for I := 0 to ARequestInfo.Params.Count - 1 do
  begin
    Name := ARequestInfo.Params.Names[I];

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

procedure TSimpleHttpServer.WriteResponse(
  const Response: THttpResponse;
  AResponseInfo: TIdHTTPResponseInfo
);
begin
  AResponseInfo.ResponseNo := Response.StatusCode;
  AResponseInfo.ContentType := Response.ContentType;
  AResponseInfo.ContentText := Response.Body;
end;

procedure TSimpleHttpServer.HandleCommand(
  AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo
);
var
  Request: THttpRequest;
  Response: THttpResponse;
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
