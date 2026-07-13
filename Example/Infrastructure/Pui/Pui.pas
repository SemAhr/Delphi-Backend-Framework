unit Pui;

interface

uses
  Pui.Port,
  Logger.Port,
  Options.Port,
  Pui.Options,
  SignIn.Response.Dto,
  PuiSignIn.Dto,
  Success.Dto,
  Report.Dto,
  Match.Dto,
  Event.Dto,
  FinalizeSearch.Dto;

type
//    error response:
//    { "error": "string" }
//    { "error": ["string"] }

  TPuiSession = record
    AccessToken: string;
    CreatedAt: TDateTime;
  end;

  TPui = class(TInterfacedObject, IPui)
  private
    FSession: TPuiSession;
    FOptions: TPuiOptions;
    FLogger: ILogger;

    function BuildUrl(const Path: string): string;

    function Get<T>(const Path: string): T;
    function Post<TRequest; TResponse>(const Path: string; const Body: TRequest): TResponse;

    procedure EnsureSignedIn;
  public
    constructor Create(const Logger: ILogger; const Options: IOptions<TPuiOptions>);

    function GetAccessToken: string;

    function GetReports: TArray<TReportDto>;
    function ReportMatch(const MatchDto: TMatchDto): Boolean; { Fase 1 }
    function ReportEvent(const EventDto: TEventDto): Boolean; { Fase 2 and 3 }
    function FinalizeSearch(const FinalizeSearchDto: TFinalizeSearchDto): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Net.URLClient,
  System.Net.HttpClient,
  AppExceptions,
  Json.Helpers,
  CustomExceptions;

constructor TPui.Create(const Logger: ILogger; const Options: IOptions<TPuiOptions>);
begin
  if Logger = nil then
    raise EMissingDependencyException.Create('Logger is required.');

  if Options = nil then
    raise EMissingDependencyException.Create('Pui options are required.');

  if Options.Value = nil then
    raise EMissingAttributeException.Create('Pui options value is required.');

  FOptions := Options.Value;

  if FOptions.BaseUrl.Trim.IsEmpty then
    raise EMissingAttributeException.Create('Pui.BaseUrl is required.');

  if FOptions.InstitutionId.Trim.IsEmpty then
    raise EMissingAttributeException.Create('Pui.InstitutionId is required.');

  if FOptions.Password.Trim.IsEmpty then
    raise EMissingAttributeException.Create('Pui.Password is required.');

  if FOptions.SessionDuration.TotalMilliseconds <= 0 then
    raise EMissingAttributeException.Create('Pui.SessionDuration is required.');

  if FOptions.SessionGraceWindow.TotalMilliseconds <= 0 then
    raise EMissingAttributeException.Create('Pui.SessionGraceWindow is required.');

  if FOptions.SessionGraceWindow >= FOptions.SessionDuration then
    raise EMissingAttributeException.Create('Pui.SessionGraceWindow must be lower than Pui.SessionDuration.');
end;

{ Private }

function TPui.BuildUrl(const Path: string): string;
begin
  Result := FOptions.BaseUrl + '/' + Path.TrimLeft(['/']);
end;

function TPui.Get<T>(const Path: string): T;
var
  Headers: TNetHeaders;
  StatusCode: Integer;
  ResponseBody: string;
begin
  var Route := BuildUrl(Path);
  var Client := THTTPClient.Create;
  try
    try
      if not FSession.AccessToken.Trim.IsEmpty then
      begin
        SetLength(Headers, 1);
        Headers[0] := TNetHeader.Create('Authorization', Format('Bearer %s', [FSession.AccessToken]));
      end;

      var Response := Client.Get(Route, nil, Headers);

      StatusCode := Response.StatusCode;
      ResponseBody := Response.ContentAsString(TEncoding.UTF8);

      if not Response.StatusCode in [200, 201, 202, 204] then
        raise EPuiException.Create(StatusCode, ResponseBody);

      Result := TJsonHelpers.ToValue<T>(ResponseBody);

      FLogger.Debug(
        'PUI GET' + sLineBreak +
        '-- route' + Route + sLineBreak +
        '-- status_code=' + StatusCode.ToString + sLineBreak +
        '-- body_response=' + ResponseBody
      );
    except
      on Error: Exception do
      begin
        FLogger.Error(
          'PUI GET' + sLineBreak +
          '-- route=' +  Route + sLineBreak +
          '-- status_code=' + StatusCode.ToString + sLineBreak +
          '-- body_response=' + ResponseBody + sLineBreak +
          '-- error_name=' + Error.ClassName + sLineBreak +
          '-- error_message' + Error.Message
        );

        raise;
      end;
    end;
  finally
    Client.Free;
  end;
end;

function TPui.Post<TRequest, TResponse>(const Path: string; const Body: TRequest): TResponse;
var
  Headers: TNetHeaders;
  StatusCode: Integer;
  ResponseBody: string;
begin
  var Route := BuildUrl(Path);
  var RequestBody := TJsonHelpers.ToString(Body, True);

  var Client := THTTPClient.Create;
  try
    try
      if not FSession.AccessToken.Trim.IsEmpty then
      begin
        SetLength(Headers, 1);
        Headers[0] := TNetHeader.Create('Authorization', Format('Bearer %s', [FSession.AccessToken]));
      end;

      var Response := Client.Post(Route, RequestBody, nil, Headers);

      StatusCode := Response.StatusCode;
      ResponseBody := Response.ContentAsString(TEncoding.UTF8);

      if not Response.StatusCode in [200, 201, 202, 204] then
        raise EPuiException.Create(StatusCode, ResponseBody);

      Result := TJsonHelpers.ToValue<TResponse>(ResponseBody);

      FLogger.Debug(
        'PUI POST' + sLineBreak +
        '-- route' + Route + sLineBreak +
        '-- request_body=' + RequestBody + sLineBreak +
        '-- status_code=' + StatusCode.ToString + sLineBreak +
        '-- body_response=' + ResponseBody
      );
    except
      on Error: Exception do
      begin
        FLogger.Error(
          'PUI POST' + sLineBreak +
          '-- route=' +  Route + sLineBreak +
          '-- request_body=' + RequestBody + sLineBreak +
          '-- status_code=' + StatusCode.ToString + sLineBreak +
          '-- body_response=' + ResponseBody + sLineBreak +
          '-- error_name=' + Error.ClassName + sLineBreak +
          '-- error_message' + Error.Message
        );

        raise;
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TPui.EnsureSignedIn;
var
  Body: TPuiSignInRequestDto;
begin
  if not FSession.AccessToken.Trim.IsEmpty then
    Exit;

  var ExpiresAt: TDateTime := FSession.CreatedAt + (FOptions.SessionDuration - FOptions.SessionGraceWindow);

  if (ExpiresAt > Now) then
    Exit;

  Body.InstitutionId := FOptions.InstitutionId; { RFC + homoclave, 4-13 }
  Body.Password := FOptions.Password; { 1-50 }

  var Response := Self.Post<TPuiSignInRequestDto, TSignInResponseDto>('login', Body);

  FSession.AccessToken := Response.AccessToken;
  FSession.CreatedAt := Now;
end;

{ End Private }

function TPui.GetAccessToken: string;
begin
  Result := FSession.AccessToken;
end;

{
1. Obtener token en PUI.
2. Consultar GET /reportes.
3. Por cada reporte:
   a. Buscar por id en tu base local.
   b. Si existe, actualizar last_seen_in_pui_at.
   c. Si no existe, insertarlo como reporte recuperado por sincronización.
4. Para reportes nuevos recuperados:
   a. Encolar fase 1 usando CURP.
   b. Encolar fase 2 solo si fecha_desaparicion existe.
   c. Crear job de fase 3 continua.
5. En fase 1:
   a. Buscar datos internos por CURP.
   b. Comparar contra datos recibidos/listados.
   c. Si hay datos útiles, notificar /notificar-coincidencia con fase_busqueda = "1".
   d. Si no hay datos útiles, omitir notificación.
6. En fase 2:
   a. Buscar eventos históricos desde fecha_desaparicion hasta hoy, máximo 12 años.
   b. Notificar cada coincidencia con fase_busqueda = "2".
   c. Al terminar, llamar /busqueda-finalizada.
7. En fase 3:
   a. Mantener búsqueda periódica de eventos nuevos/modificados.
   b. Notificar coincidencias con fase_busqueda = "3".
}
function TPui.GetReports: TArray<TReportDto>;
begin
  EnsureSignedIn;
  Result := Self.Get<TArray<TReportDto>>('notificar-coincidencia');
end;

function TPui.ReportMatch(const MatchDto: TMatchDto): Boolean;
begin
  EnsureSignedIn;

  var Response := Self.Post<TMatchDto, TSuccessDto>('notificar-coincidencia', MatchDto);
  Result := not Response.Message.Trim.IsEmpty;
end;

function TPui.ReportEvent(const EventDto: TEventDto): Boolean;
begin
  EnsureSignedIn;

  var Response := Self.Post<TEventDto, TSuccessDto>('notificar-coincidencia', EventDto);
  Result := not Response.Message.Trim.IsEmpty;
end;

function TPui.FinalizeSearch(const FinalizeSearchDto: TFinalizeSearchDto): Boolean;
begin
  EnsureSignedIn;

  var Response := Self.Post<TFinalizeSearchDto, TSuccessDto>('finalizar-busqueda', FinalizeSearchDto);
  Result := not Response.Message.Trim.IsEmpty;
end;

end.
