unit Http.RouteDescriptor;

interface

uses
  System.Rtti,
  System.SysUtils,
  Http.ParameterDescriptor;

type
  TRouteDescriptor = class
  private
    FMethod: string;
    FPath: string;
    FControllerType: TRttiInstanceType;
    FMethodInfo: TRttiMethod;
    FParameters: TArray<TParameterDescriptor>;
  public
    constructor Create(
      const AMethod: string;
      const APath: string;
      const AControllerType: TRttiInstanceType;
      const AMethodInfo: TRttiMethod;
      const AParameters: TArray<TParameterDescriptor>
    );

    property Method: string read FMethod;
    property Path: string read FPath;
    property ControllerType: TRttiInstanceType read FControllerType;
    property MethodInfo: TRttiMethod read FMethodInfo;
    property Parameters: TArray<TParameterDescriptor> read FParameters;
  end;

implementation

constructor TRouteDescriptor.Create(
  const Method: string;
  const Path: string;
  const ControllerType: TRttiInstanceType;
  const MethodInfo: TRttiMethod
);
begin
  inherited Create;
  FMethod := UpperCase(Method);
  FPath := Path;
  FControllerType := ControllerType;
  FMethodInfo := MethodInfo;
end;

end.
