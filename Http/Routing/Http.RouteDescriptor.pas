unit Http.RouteDescriptor;

interface

uses
  System.Rtti,
  System.SysUtils,
  Http.ParameterDescriptor,
  Http.Middleware.Descriptor;

type
  /// <summary>
  /// Describes a single HTTP route discovered from a controller action.
  /// </summary>
  /// <remarks>
  /// Route descriptors are created during controller scanning and later used by the router to match
  /// requests, resolve the target controller, bind action parameters, and invoke the controller method.
  /// </remarks>
  TRouteDescriptor = class
  private
    FMethod: string;
    FPath: string;
    FControllerType: TRttiInstanceType;
    FMethodInfo: TRttiMethod;
    FParameters: TArray<TParameterDescriptor>;
    FMiddlewares: TArray<TMiddlewareDescriptor>;
    FAttributes: TArray<TCustomAttribute>;
  public
    /// <summary>
    /// Creates a route descriptor for one controller action.
    /// </summary>
    /// <param name="AMethod">HTTP verb used to match the request, for example GET or POST.</param>
    /// <param name="APath">Normalized route path used by the router for path matching.</param>
    /// <param name="AControllerType">RTTI type of the controller class that owns the action.</param>
    /// <param name="AMethodInfo">RTTI metadata of the controller method to invoke.</param>
    /// <param name="AParameters">Binding descriptors for every method parameter.</param>
    constructor Create(
      const AMethod: string;
      const APath: string;
      const AControllerType: TRttiInstanceType;
      const AMethodInfo: TRttiMethod;
      const AParameters: TArray<TParameterDescriptor>;
      const AMiddlewares: TArray<TMiddlewareDescriptor>;
      const AAttributes: TArray<TCustomAttribute>
    );

    /// <summary>
    /// HTTP verb required by this route. Stored uppercase to simplify request matching.
    /// </summary>
    property Method: string read FMethod;

    /// <summary>
    /// Full route path produced by combining the controller route and action route attributes.
    /// </summary>
    property Path: string read FPath;

    /// <summary>
    /// Controller class type used by the action invoker to resolve an instance from the container.
    /// </summary>
    property ControllerType: TRttiInstanceType read FControllerType;

    /// <summary>
    /// Controller method metadata used to invoke the action through RTTI.
    /// </summary>
    property MethodInfo: TRttiMethod read FMethodInfo;

    /// <summary>
    /// Parameter binding metadata used to build the argument list before invoking MethodInfo.
    /// </summary>
    property Parameters: TArray<TParameterDescriptor> read FParameters;

    property Middlewares: TArray<TMiddlewareDescriptor> read FMiddlewares;

    property Attributes: TArray<TCustomAttribute> read FAttributes;
  end;

implementation

constructor TRouteDescriptor.Create(
  const AMethod: string;
  const APath: string;
  const AControllerType: TRttiInstanceType;
  const AMethodInfo: TRttiMethod;
  const AParameters: TArray<TParameterDescriptor>;
  const AMiddlewares: TArray<TMiddlewareDescriptor>;
  const AAttributes: TArray<TCustomAttribute>
);
begin
  inherited Create;
  FMethod := UpperCase(AMethod);
  FPath := APath;
  FControllerType := AControllerType;
  FMethodInfo := AMethodInfo;
  FParameters := AParameters;
  FMiddlewares := AMiddlewares;
  FAttributes := AAttributes;
end;
end.
