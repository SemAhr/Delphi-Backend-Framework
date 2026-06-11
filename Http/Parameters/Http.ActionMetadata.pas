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
      const Parameter: TRttiParameter;
      out SourceName: string
    ): TParameterSource;

  public
    function CreateMetadata(const MethodInfo: TRttiMethod): TActionMetadata;
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
  const Parameter: TRttiParameter;
  out SourceName: string
): TParameterSource;
var
  Attr: TCustomAttribute;
begin
  Result := psUnknown;
  SourceName := '';

  for Attr in Parameter.GetAttributes do
  begin
    if Attr is FromContextAttribute then
      Exit(psContext);

    if Attr is FromRouteAttribute then
    begin
      SourceName := FromRouteAttribute(Attr).Name;
      Exit(psRoute);
    end;

    if Attr is FromQueryAttribute then
    begin
      SourceName := FromQueryAttribute(Attr).Name;
      Exit(psQuery);
    end;

    if Attr is FromHeaderAttribute then
    begin
      SourceName := FromHeaderAttribute(Attr).Name;
      Exit(psHeader);
    end;

    if Attr is FromBodyAttribute then
      Exit(psBody);
  end;
end;

function TActionMetadataFactory.CreateMetadata(
  const MethodInfo: TRttiMethod
): TActionMetadata;
var
  RttiParams: TArray<TRttiParameter>;
  Descriptors: TArray<TParameterDescriptor>;
  Index: Integer;
  SourceName: string;
  Source: TParameterSource;
begin
  RttiParams := MethodInfo.GetParameters;
  SetLength(Descriptors, Length(RttiParams));

  for Index := 0 to High(RttiParams) do
  begin
    Source := GetParameterSource(RttiParams[Index], SourceName);

    if Source = psUnknown then
      raise Exception.CreateFmt(
        'Parameter "%s" in method "%s" must have a binding attribute.',
        [RttiParams[Index].Name, MethodInfo.Name]
      );

    if SourceName = '' then
      SourceName := RttiParams[Index].Name;

    Descriptors[Index].Name := RttiParams[Index].Name;
    Descriptors[Index].Source := Source;
    Descriptors[Index].SourceName := SourceName;
    Descriptors[Index].RttiParameter := RttiParams[Index];
    Descriptors[Index].ParameterType := RttiParams[Index].ParamType;
  end;

  Result := TActionMetadata.Create(MethodInfo, Descriptors);
end;

end.
