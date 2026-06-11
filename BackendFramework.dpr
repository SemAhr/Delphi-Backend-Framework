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
  Http.ControllerScanner in 'Http\Controllers\Http.ControllerScanner.pas',
  Http.AttributeRouter in 'Http\Attributes\Http.AttributeRouter.pas',
  Http.Server in 'Http\Http.Server.pas',
  Http.Parameter.Attributes in 'Http\Parameters\Http.Parameter.Attributes.pas',
  Http.Context in 'Http\Context\Http.Context.pas',
  Http.Parameter.Binding in 'Http\Parameters\Http.Parameter.Binding.pas',
  Http.ParameterDescriptor in 'Http\Parameters\Http.ParameterDescriptor.pas',
  Http.ActionMetadata in 'Http\Parameters\Http.ActionMetadata.pas',
  Http.ValueConverter in 'Http\Parameters\Http.ValueConverter.pas',
  Http.ParameterBinder in 'Http\Parameters\Http.ParameterBinder.pas',
  HttpExceptions in 'Common\Exceptions\HttpExceptions.pas',
  Http.ActionInvoker in 'Http\Controllers\Http.ActionInvoker.pas',
  AppExceptions in 'Common\Exceptions\AppExceptions.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
