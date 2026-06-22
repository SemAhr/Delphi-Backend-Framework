unit Http.ParameterDescriptor;

interface

uses
  System.Rtti,
  Http.Parameter.Binding;

type
  TParameterDescriptor = record
  public
    Name: string;
    Source: TParameterSource;
    SourceName: string;
    RttiParameter: TRttiParameter;
    ParameterType: TRttiType;
end;

implementation

end.
