unit Http.ControllerScanner;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Http.Attributes,
  Http.Controller.Contract,
  Http.RouteDescriptor;

type
  TControllerScanner = class
  private
    FRttiContext: TRttiContext;
function GetControllerBasePath(ARttiType: TRttiType) : string;
function CombinePaths(const ABasePath, AMethodPath: string): string;
function ImplementsHttpController(ARttiType: TRttiType) : Boolean;
public
    constructor Create;
function Scan(const AControllerClasses: array of TClass) : TObjectList<TRouteDescriptor>;
end;

implementation

uses
  Http.ActionMetadata;
constructor TControllerScanner.Create;
begin
  inherited Create;
  FRttiContext := TRttiContext.Create;
end;
function TControllerScanner.GetControllerBasePath(ARttiType: TRttiType) : string;
var
  Attr: TCustomAttribute;
begin
  Result := '';

  for Attr in ARttiType.GetAttributes do
  begin
    if Attr is RouteAttribute then
      Exit(RouteAttribute(Attr).Path);
end;
end;
function TControllerScanner.CombinePaths(const ABasePath, AMethodPath: string) : string;
var
  BasePath: string;
  MethodPath: string;
begin
  BasePath := ABasePath.Trim;
  MethodPath := AMethodPath.Trim;

  if BasePath = '' then
    BasePath := '/';

  if not BasePath.StartsWith('/') then
    BasePath := '/' + BasePath;

  BasePath := BasePath.TrimRight(['/']);

  if MethodPath = '' then
    Exit(BasePath);

  if not MethodPath.StartsWith('/') then
    MethodPath := '/' + MethodPath;

  Result := BasePath + MethodPath;
end;
function TControllerScanner.ImplementsHttpController(ARttiType: TRttiType) : Boolean;
var
  InstanceType: TRttiInstanceType;
  InterfaceType: TRttiInterfaceType;
begin
  Result := False;

  if not (ARttiType is TRttiInstanceType) then
    Exit;

  InstanceType := TRttiInstanceType(ARttiType);

  for InterfaceType in InstanceType.GetImplementedInterfaces do
  begin
    if InterfaceType.GUID = IHttpController then
      Exit(True);
end;
end;
function TControllerScanner.Scan(const AControllerClasses: array of TClass) : TObjectList<TRouteDescriptor>;
var
  ControllerClass: TClass;
  ControllerType: TRttiType;
  InstanceType: TRttiInstanceType;
  MethodInfo: TRttiMethod;
  Attr: TCustomAttribute;
  BasePath: string;
  FullPath: string;
  HttpAttr: HttpMethodAttribute;
  MetadataFactory: TActionMetadataFactory;
  Metadata: TActionMetadata;
begin
  Result := TObjectList<TRouteDescriptor>.Create(True);
  MetadataFactory := TActionMetadataFactory.Create;

  try
    try
      for ControllerClass in AControllerClasses do
      begin
        ControllerType := FRttiContext.GetType(ControllerClass);

        if not ImplementsHttpController(ControllerType) then
          raise Exception.CreateFmt(
            'Controller "%s" must implement IHttpController.',
            [ControllerClass.ClassName]
          );

        if not (ControllerType is TRttiInstanceType) then
          Continue;

        InstanceType := TRttiInstanceType(ControllerType);
        BasePath := GetControllerBasePath(ControllerType);

        for MethodInfo in ControllerType.GetMethods do
        begin
          for Attr in MethodInfo.GetAttributes do
          begin
            if Attr is HttpMethodAttribute then
            begin
              HttpAttr := HttpMethodAttribute(Attr);
              FullPath := CombinePaths(BasePath, HttpAttr.Path);
              Metadata := MetadataFactory.CreateMetadata(MethodInfo);

              try
                Result.Add(
                  TRouteDescriptor.Create(
                    HttpAttr.Method,
                    FullPath,
                    InstanceType,
                    MethodInfo,
                    Metadata.Parameters
                  )
                );
              finally
                Metadata.Free;
end;
end;
end;
end;
end;
    except
      Result.Free;
      raise;
end;
  finally
    MetadataFactory.Free;
end;
end;
end.
