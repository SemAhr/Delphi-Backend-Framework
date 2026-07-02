unit Inet.Helpers;

interface

type
  TIpVersion = (Unknown, Ipv4, Ipv6);

  TIp = record
  private
    const Ipv4Regex = '^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$';
    const Ipv6Regex = '^((?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,7}:|(?:[0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,5}(?::[0-9A-Fa-f]{1,4}){1,2}|(?:[0-9A-Fa-f]{1,4}:){1,4}(?::[0-9A-Fa-f]{1,4}){1,3}|(?:[0-9A-Fa-f]{1,4}:){1,3}(?::[0-9A-Fa-f]{1,4}){1,4}|(?:[0-9A-Fa-f]{1,4}:){1,2}(?::[0-9A-Fa-f]{1,4}){1,5}|[0-9A-Fa-f]{1,4}:(?:(?::[0-9A-Fa-f]{1,4}){1,6})|:(?:(?::[0-9A-Fa-f]{1,4}){1,7}|:)|fe80:(?::[0-9A-Fa-f]{0,4}){0,4}%[0-9A-Za-z]+|::(?:ffff(?::0{1,4})?:)?(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)|(?:[0-9A-Fa-f]{1,4}:){1,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d))$';
  public
    Value: string;
    Version: TIpVersion;

    class function ParseIp(const Value: string): TIp; static;
    class function TryParseIp(const Value: string; out Ip: TIp): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions;

class function TIp.ParseIp(const Value: string): TIp;
begin
  Result.Version := TIpVersion.Unknown;

  var NormalizedIpValue := Value.Trim;

  if NormalizedIpValue.IsEmpty then
    Exit;

  if TRegEx.IsMatch(NormalizedIpValue, Ipv4Regex) then
  begin
    Result.Value := NormalizedIpValue;
    Result.Version := TIpVersion.Ipv4;
    Exit;
  end;

  if TRegEx.IsMatch(NormalizedIpValue, Ipv6Regex) then
  begin
    Result.Value := NormalizedIpValue;
    Result.Version := TIpVersion.Ipv6;
    Exit;
  end;
end;

class function TIp.TryParseIp(const Value: string; out Ip: TIp): Boolean;
var
  NormalizedIpValue: string;
begin
  Result := False;

  try
    Ip := ParseIp(Value);
    Result := True;
  except
  end;
end;

end.
