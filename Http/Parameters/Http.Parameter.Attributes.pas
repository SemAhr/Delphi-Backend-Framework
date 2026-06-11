unit Http.Parameter.Attributes;

interface

uses
  System.SysUtils;

type
  FromContextAttribute = class(TCustomAttribute);

  FromRouteAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string = '');
    property Name: string read FName;
  end;

  FromQueryAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string = '');
    property Name: string read FName;
  end;

  FromHeaderAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string = '');
    property Name: string read FName;
  end;

  FromBodyAttribute = class(TCustomAttribute);

implementation

constructor FromRouteAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName.Trim;
end;

constructor FromQueryAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName.Trim;
end;

constructor FromHeaderAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := LowerCase(AName.Trim);
end;

end.
