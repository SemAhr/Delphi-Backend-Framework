program BackendFramework;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Http.Controller.Contract in 'Http\Controllers\Http.Controller.Contract.pas',
  Http.Attributes in 'Http\Attributes\Http.Attributes.pas',
  Common.Container.Contract in 'Common\Container\Common.Container.Contract.pas',
  Http.Core in 'Http\Http.Core.pas',
  Http.RouteDescriptor in 'Http\Routes\Http.RouteDescriptor.pas',
  Http.Router.Contract in 'Http\Routes\Http.Router.Contract.pas',
  Http.ControllerScanner in 'Http\Controllers\Http.ControllerScanner.pas',
  Http.ActionInvoker.Contract in 'Http\Controllers\Http.ActionInvoker.Contract.pas',
  Http.AttributeRouter in 'Http\Attributes\Http.AttributeRouter.pas',
  Http.Server in 'Http\Http.Server.pas',
  Http.Parameter.Attributes in 'Http\Parameters\Http.Parameter.Attributes.pas',
  Http.Context in 'Http\Context\Http.Context.pas',
  Http.Parameter.Binding in 'Http\Parameters\Http.Parameter.Binding.pas',
  Http.ParameterDescriptor in 'Http\Parameters\Http.ParameterDescriptor.pas',
  Http.ActionMetadata in 'Http\Parameters\Http.ActionMetadata.pas',
  Http.ValueConverter in 'Http\Parameters\Http.ValueConverter.pas',
  Http.BodyBinder.Contract in 'Http\Parameters\Http.BodyBinder.Contract.pas',
  Http.ParameterBinder.Contract in 'Http\Parameters\Http.ParameterBinder.Contract.pas',
  Http.JsonBodyBinder in 'Http\Parameters\Http.JsonBodyBinder.pas',
  Http.ParameterBinder in 'Http\Parameters\Http.ParameterBinder.pas',
  HttpExceptions in 'Common\Exceptions\HttpExceptions.pas',
  Http.ActionInvoker in 'Http\Controllers\Http.ActionInvoker.pas',
  AppExceptions in 'Common\Exceptions\AppExceptions.pas',
  RttiAttribute.Helpers in 'Common\Helpers\RttiAttribute.Helpers.pas',
  Dto.Attributes in 'Common\Dtos\Attributes\Dto.Attributes.pas',
  Dto.Binder.Port in 'Common\Dtos\Binding\Ports\Dto.Binder.Port.pas',
  Dto.Binder in 'Common\Dtos\Binding\Dto.Binder.pas',
  Dto.Metadata in 'Common\Dtos\Validation\Dto.Metadata.pas',
  Dto.TypeInspector in 'Common\Dtos\Validation\Dto.TypeInspector.pas',
  Dto.Validation.Context in 'Common\Dtos\Validation\Dto.Validation.Context.pas',
  DtoBoolean.Validator in 'Common\Dtos\Validation\Validators\DtoBoolean.Validator.pas',
  DtoDate.Validator in 'Common\Dtos\Validation\Validators\DtoDate.Validator.pas',
  DtoNumber.Validator in 'Common\Dtos\Validation\Validators\DtoNumber.Validator.pas',
  DtoRequired.Validator in 'Common\Dtos\Validation\Validators\DtoRequired.Validator.pas',
  DtoString.Validator in 'Common\Dtos\Validation\Validators\DtoString.Validator.pas',
  Http.Composition in 'Http\Http.Composition.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
