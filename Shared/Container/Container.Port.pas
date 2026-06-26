unit Container.Port;

interface

uses
  System.TypInfo;

type
  IContainer = interface;

  TServiceLifetime = (
    slSingleton,
    slTransient,
    slScoped
  );

  TServiceFactory = reference to function(const AContainer: IContainer): TObject;

  IContainer = interface
    ['{c5946003-6eda-4cbd-974f-49b3984624b0}']

    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AImplementationType: TClass); overload;
    procedure AddSingleton(const ATypeInfo: PTypeInfo; const AInstance: TObject); overload;
    procedure AddTransient(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
    procedure AddScoped(const ATypeInfo: PTypeInfo; const AImplementationType: TClass);
    procedure AddFactory(
      const ATypeInfo: PTypeInfo;
      const AFactory: TServiceFactory;
      const ALifetime: TServiceLifetime
    );

    function Resolve(const ATypeInfo: PTypeInfo): TObject;
    function CreateScope: IContainer;
  end;

implementation

end.
