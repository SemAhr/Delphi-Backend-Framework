unit Http.ActionMetadata;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Http.Parameter.Binding,
  Http.ParameterDescriptor;

type
  TActionMetadata = class
  private
    FMethod: TRttiMethod;
    FParameters: TArray<TParameterDescriptor>;
  public
    constructor Create(
      const AMethod: TRttiMethod;
      const AParameters: TArray<TParameterDescriptor>
    );

    property MethodInfo: TRttiMethod read FMethod;
    property Parameters: TArray<TParameterDescriptor> read FParameters;
  end;

  TActionMetadataFactory = class
  private
    function GetParameterSource(
      const AParameter: TRttiParameter;
      out ASourceName: string
    ): TParameterSource;

  public
    function CreateMetadata(const AMethodInfo: TRttiMethod): TActionMetadata;
  end;

implementation

uses
  Http.Parameter.Attributes;

constructor TActionMetadata.Create(
  const AMethod: TRttiMethod;
  const AParameters: TArray<TParameterDescriptor>
);
begin
  inherited Create;
  FMethod := AMethod;
  FParameters := AParameters;
end;

function TActionMetadataFactory.GetParameterSource(
  const AParameter: TRttiParameter;
  out ASourceName: string
): TParameterSource;
var
  Attr: TCustomAttribute;
begin
  Result := psUnknown;
  ASourceName := '';

  for Attr in AParameter.GetAttributes do
  begin
    if Attr is FromContextAttribute then
      Exit(psContext);

    if Attr is FromRouteAttribute then
    begin
      ASourceName := FromRouteAttribute(Attr).Name;
      Exit(psRoute);
    end;

    if Attr is FromQueryAttribute then
    begin
      ASourceName := FromQueryAttribute(Attr).Name;
      Exit(psQuery);
    end;

    if Attr is FromHeaderAttribute then
    begin
      ASourceName := FromHeaderAttribute(Attr).Name;
      Exit(psHeader);
    end;

    if Attr is FromBodyAttribute then
      Exit(psBody);
  end;
end;

function TActionMetadataFactory.CreateMetadata(
  const AMethodInfo: TRttiMethod
): TActionMetadata;
var
  RttiParams: TArray<TRttiParameter>;
  Descriptors: TArray<TParameterDescriptor>;
  Index: Integer;
  SourceName: string;
  Source: TParameterSource;
begin
  RttiParams := AMethodInfo.GetParameters;
  SetLength(Descriptors, Length(RttiParams));

  for Index := 0 to High(RttiParams) do
  begin
    Source := GetParameterSource(RttiParams[Index], SourceName);

    if Source = psUnknown then
      raise Exception.CreateFmt(
        'Parameter "%s" in method "%s" must have a binding attribute.',
        [RttiParams[Index].Name, AMethodInfo.Name]
      );

    if SourceName = '' then
      SourceName := RttiParams[Index].Name;

    Descriptors[Index].Name := RttiParams[Index].Name;
    Descriptors[Index].Source := Source;
    Descriptors[Index].SourceName := SourceName;
    Descriptors[Index].RttiParameter := RttiParams[Index];
    Descriptors[Index].ParameterType := RttiParams[Index].ParamType;
  end;

  Result := TActionMetadata.Create(AMethodInfo, Descriptors);
end;

end.
