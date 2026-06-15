program BackendFramework;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Shared.Container.Contract in 'Shared\Container\Shared.Container.Contract.pas',
  Shared.AppExceptions in 'Shared\Exceptions\Shared.AppExceptions.pas',
  Shared.HttpExceptions in 'Shared\Exceptions\Shared.HttpExceptions.pas',
  Shared.RttiAttribute.Helpers in 'Shared\Rtti\Shared.RttiAttribute.Helpers.pas',
  Dto.Attributes in 'Dto\Attributes\Dto.Attributes.pas',
  Dto.Binder.Contract in 'Dto\Binding\Dto.Binder.Contract.pas',
  Dto.Binder in 'Dto\Binding\Dto.Binder.pas',
  Dto.Metadata in 'Dto\Validation\Dto.Metadata.pas',
  Dto.TypeInspector in 'Dto\Validation\Dto.TypeInspector.pas',
  Dto.Validation.Context in 'Dto\Validation\Dto.Validation.Context.pas',
  Dto.Validation.BooleanValidator in 'Dto\Validation\Validators\Dto.Validation.BooleanValidator.pas',
  Dto.Validation.DateValidator in 'Dto\Validation\Validators\Dto.Validation.DateValidator.pas',
  Dto.Validation.NumberValidator in 'Dto\Validation\Validators\Dto.Validation.NumberValidator.pas',
  Dto.Validation.RequiredValidator in 'Dto\Validation\Validators\Dto.Validation.RequiredValidator.pas',
  Dto.Validation.StringValidator in 'Dto\Validation\Validators\Dto.Validation.StringValidator.pas',
  Http.Controller.Contract in 'Http\Controllers\Http.Controller.Contract.pas',
  Http.Attributes in 'Http\Attributes\Http.Attributes.pas',
  Http.Core in 'Http\Http.Core.pas',
  Http.Context in 'Http\Context\Http.Context.pas',
  Http.RouteDescriptor in 'Http\Routing\Http.RouteDescriptor.pas',
  Http.Router.Contract in 'Http\Routing\Http.Router.Contract.pas',
  Http.ControllerScanner in 'Http\Routing\Http.ControllerScanner.pas',
  Http.ActionInvoker.Contract in 'Http\Routing\Http.ActionInvoker.Contract.pas',
  Http.AttributeRouter in 'Http\Routing\Http.AttributeRouter.pas',
  Http.ActionInvoker in 'Http\Routing\Http.ActionInvoker.pas',
  Http.Server in 'Http\Http.Server.pas',
  Http.Parameter.Attributes in 'Http\Parameters\Http.Parameter.Attributes.pas',
  Http.Parameter.Binding in 'Http\Parameters\Http.Parameter.Binding.pas',
  Http.ParameterDescriptor in 'Http\Parameters\Http.ParameterDescriptor.pas',
  Http.ActionMetadata in 'Http\Parameters\Http.ActionMetadata.pas',
  Http.ValueConverter in 'Http\Parameters\Http.ValueConverter.pas',
  Http.BodyBinder.Contract in 'Http\Parameters\Http.BodyBinder.Contract.pas',
  Http.ParameterBinder.Contract in 'Http\Parameters\Http.ParameterBinder.Contract.pas',
  Http.JsonBodyBinder in 'Http\Parameters\Http.JsonBodyBinder.pas',
  Http.ParameterBinder in 'Http\Parameters\Http.ParameterBinder.pas',
  Http.Composition in 'Http\Http.Composition.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
