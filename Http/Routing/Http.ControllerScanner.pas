unit Http.ControllerScanner;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Http.Attributes,
  Http.Controller.Port,
  Http.RouteDescriptor;

type
  TControllerScanner = class
  private
    FRttiContext: TRttiContext;

    function GetControllerBasePath(const ARttiType: TRttiType): string;
    function CombinePaths(const ABasePath, AMethodPath: string): string;
    function ImplementsController(const ARttiType: TRttiType): Boolean;
  public
    constructor Create;

    function Execute(const AControllerClasses: array of TClass): TObjectList<TRouteDescriptor>;
  end;

implementation

uses
  Http.ActionMetadata;

constructor TControllerScanner.Create;
begin
  inherited Create;
  FRttiContext := TRttiContext.Create;
end;

function TControllerScanner.GetControllerBasePath(const ARttiType: TRttiType): string;
begin
  Result := '';

  for var Attribute in ARttiType.GetAttributes do
  begin
    if Attribute is RouteAttribute then
      Exit(RouteAttribute(Attribute).Path);
  end;
end;

function TControllerScanner.CombinePaths(const ABasePath, AMethodPath: string): string;
begin
  var BasePath := ABasePath.Trim;
  var MethodPath := AMethodPath.Trim;

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

function TControllerScanner.ImplementsController(const ARttiType: TRttiType): Boolean;
begin
  Result := False;

  if not (ARttiType is TRttiInstanceType) then
    Exit;

  var InstanceType := TRttiInstanceType(ARttiType);

  for var InterfaceType in InstanceType.GetImplementedInterfaces do
  begin
    if InterfaceType.GUID = IController then
      Exit(True);
  end;
end;

function TControllerScanner.Execute(const AControllerClasses: array of TClass): TObjectList<TRouteDescriptor>;
begin
  Result := TObjectList<TRouteDescriptor>.Create(True);
  var MetadataFactory := TActionMetadataFactory.Create;

  try
    try
      for var ControllerClass in AControllerClasses do
      begin
        var ControllerType := FRttiContext.GetType(ControllerClass);

        if not ImplementsController(ControllerType) then
          raise Exception.CreateFmt(
            'Controller "%s" must implement IController.',
            [ControllerClass.ClassName]
          );

        if not (ControllerType is TRttiInstanceType) then
          Continue;

        var InstanceType := TRttiInstanceType(ControllerType);
        var BasePath := GetControllerBasePath(ControllerType);

        for var MethodInfo in ControllerType.GetMethods do
        begin
          for var Attribute in MethodInfo.GetAttributes do
          begin
            if Attribute is HttpMethodAttribute then
            begin
              var HttpAttribute := HttpMethodAttribute(Attribute);
              var FullPath := CombinePaths(BasePath, HttpAttribute.Path);
              var Metadata := MetadataFactory.CreateMetadata(MethodInfo);

              try
                Result.Add(
                  TRouteDescriptor.Create(
                    HttpAttribute.Method,
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
