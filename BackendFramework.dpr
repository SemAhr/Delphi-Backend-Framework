program BackendFramework;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Container.Port in 'Shared\Container\Container.Port.pas',
  AppExceptions in 'Shared\Exceptions\AppExceptions.pas',
  HttpExceptions in 'Shared\Exceptions\HttpExceptions.pas',
  Dto.Attributes in 'Dto\Attributes\Dto.Attributes.pas',
  Dto.Binder.Port in 'Dto\Binding\Dto.Binder.Port.pas',
  Dto.Binder in 'Dto\Binding\Dto.Binder.pas',
  Dto.Metadata in 'Dto\Validation\Dto.Metadata.pas',
  Dto.TypeInspector in 'Dto\Validation\Dto.TypeInspector.pas',
  Dto.Validation.Context in 'Dto\Validation\Dto.Validation.Context.pas',
  Dto.Validation.BooleanValidator in 'Dto\Validation\Validators\Dto.Validation.BooleanValidator.pas',
  Dto.Validation.DateValidator in 'Dto\Validation\Validators\Dto.Validation.DateValidator.pas',
  Dto.Validation.NumberValidator in 'Dto\Validation\Validators\Dto.Validation.NumberValidator.pas',
  Dto.Validation.RequiredValidator in 'Dto\Validation\Validators\Dto.Validation.RequiredValidator.pas',
  Dto.Validation.StringValidator in 'Dto\Validation\Validators\Dto.Validation.StringValidator.pas',
  Http.Controller.Port in 'Http\Controllers\Http.Controller.Port.pas',
  Http.Attributes in 'Http\Attributes\Http.Attributes.pas',
  Http.Core in 'Http\Http.Core.pas',
  Http.Context in 'Http\Context\Http.Context.pas',
  Http.RouteDescriptor in 'Http\Routing\Http.RouteDescriptor.pas',
  Http.Router.Port in 'Http\Routing\Http.Router.Port.pas',
  Http.ControllerScanner in 'Http\Routing\Http.ControllerScanner.pas',
  Http.ActionInvoker.Port in 'Http\Routing\Http.ActionInvoker.Port.pas',
  Http.Router in 'Http\Routing\Http.Router.pas',
  Http.ActionInvoker in 'Http\Routing\Http.ActionInvoker.pas',
  Http.Server in 'Http\Http.Server.pas',
  Http.Parameter.Attributes in 'Http\Parameters\Http.Parameter.Attributes.pas',
  Http.Parameter.Binding in 'Http\Parameters\Http.Parameter.Binding.pas',
  Http.ParameterDescriptor in 'Http\Parameters\Http.ParameterDescriptor.pas',
  Http.ActionMetadata in 'Http\Parameters\Http.ActionMetadata.pas',
  Http.ValueConverter in 'Http\Parameters\Http.ValueConverter.pas',
  Http.BodyBinder.Port in 'Http\Parameters\Http.BodyBinder.Port.pas',
  Http.ParameterBinder.Port in 'Http\Parameters\Http.ParameterBinder.Port.pas',
  Http.BodyBinder in 'Http\Parameters\Http.BodyBinder.pas',
  Http.ParameterBinder in 'Http\Parameters\Http.ParameterBinder.pas',
  Http.Composition in 'Http\Http.Composition.pas',
  Clabe.Helpers in 'Shared\Helpers\Clabe.Helpers.pas',
  Date.Helpers in 'Shared\Helpers\Date.Helpers.pas',
  Env.Helpers in 'Shared\Helpers\Env.Helpers.pas',
  Inet.Helpers in 'Shared\Helpers\Inet.Helpers.pas',
  Json.Helpers in 'Shared\Helpers\Json.Helpers.pas',
  Path.Helpers in 'Shared\Helpers\Path.Helpers.pas',
  RttiAttribute.Helpers in 'Shared\Helpers\RttiAttribute.Helpers.pas',
  StringArray.Helpers in 'Shared\Helpers\StringArray.Helpers.pas',
  Options.Port in 'Shared\Options\Options.Port.pas',
  Logger.Port in 'Shared\Logging\Logger.Port.pas',
  Auth.Controller in 'Src\Presentation\Controllers\Auth.Controller.pas',
  Jwt.Entity in 'Src\Domain\Jwt.Entity.pas',
  Role in 'Src\Domain\Role.pas',
  Bootstrap in 'Src\Bootstrap.pas',
  Dto.Binder.Context in 'Dto\Context\Dto.Binder.Context.pas',
  Error.Dto in 'Dto\Contracts\Error.Dto.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
