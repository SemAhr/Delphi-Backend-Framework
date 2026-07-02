unit Options.Port;

interface

type
  TOptionsLoader<T> = reference to function: T;

  IOptions<T> = interface
    ['{9761434b-af2e-44ff-9996-a778beae920a}']
    function GetValue: T;

    property Value: T read GetValue;
  end;

  TOptions<T> = class(TInterfacedObject, IOptions<T>)
  private
    FValue: T;
  public
    constructor Create(const Value: T);

    class function From(const Value: T): IOptions<T>; static;

    function GetValue: T;
  end;

implementation

constructor TOptions<T>.Create(const Value: T);
begin
  inherited Create;
  FValue := Value;
end;

class function TOptions<T>.From(const Value: T): IOptions<T>;
begin
  Result := TOptions<T>.Create(Value);
end;

function TOptions<T>.GetValue: T;
begin
  Result := FValue;
end;

end.
