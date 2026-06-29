unit Http.ParameterDescriptor;

interface

uses
  System.Rtti,
  Http.Parameter.Binding;

type
  /// <summary>
  /// Describes how a controller action parameter must be bound from the current HTTP request.
  /// </summary>
  /// <remarks>
  /// Parameter descriptors are created when controller routes are scanned. At request time,
  /// TParameterBinder reads this metadata to decide whether the value should come from route
  /// parameters, query string, headers, body, or the HTTP context itself.
  /// </remarks>
  TParameterDescriptor = record
  public
    /// <summary>
    /// Original Delphi parameter name as declared in the controller action.
    /// </summary>
    Name: string;

    /// <summary>
    /// Binding source selected from the parameter attribute, such as FromRoute or FromBody.
    /// </summary>
    Source: TParameterSource;

    /// <summary>
    /// External request name used to read the value from the selected source.
    /// </summary>
    /// <remarks>
    /// When an attribute does not provide an explicit name, this defaults to Name. For example,
    /// [FromRoute('id')] sets SourceName to 'id', while [FromRoute] uses the parameter name.
    /// </remarks>
    SourceName: string;

    /// <summary>
    /// RTTI parameter metadata kept for diagnostics and future reflection-based features.
    /// </summary>
    RttiParameter: TRttiParameter;

    /// <summary>
    /// Runtime type of the parameter. The binder uses it to convert raw request values into TValue.
    /// </summary>
    ParameterType: TRttiType;
  end;

implementation

end.
