# BackendFramework Documentation

BackendFramework is a Delphi HTTP backend framework built around explicit dependency registration, attribute-based routing, DTO binding/validation, middleware pipelines, and typed application options.

## Documentation sections

1. [Architecture overview](./Docs/01-architecture-overview.md)
2. [Dependency container](./Docs/02-dependency-container.md)
3. [Options and configuration](./Docs/03-options-and-configuration.md)
4. [Logging](./Docs/04-logging.md)
5. [Controllers and routing](./Docs/05-controllers-and-routing.md)
6. [DTOs and validation](./Docs/06-dtos-and-validation.md)
7. [Parameter binding](./Docs/07-parameter-binding.md)
8. [Middlewares](./Docs/08-middlewares.md)
9. [Custom attributes](./Docs/09-custom-attributes.md)
10. [HTTP responses](./Docs/10-http-responses.md)
11. [JSON configuration](./Docs/11-json-configuration.md)
12. [Project conventions](./Docs/12-project-conventions.md)

## High-level request flow

```mermaid
flowchart TD
    A[HTTP request] --> B[Router]
    B --> C[Route descriptor]
    C --> D[Request scope]
    D --> E[Middleware pipeline]
    E --> F[Endpoint attribute handlers]
    F --> G[Action invoker]
    G --> H[Controller action]
    H --> I[HTTP response]
```
