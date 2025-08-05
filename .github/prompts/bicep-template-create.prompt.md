# ThorLabs Bicep Template Creation

Create new Azure infrastructure using ThorLabs patterns and naming conventions.

## Context
@workspace - Current ThorLabs infrastructure  
#01-foundation.bicep - Foundation layer patterns
#02-security.bicep - Security layer patterns
#bicep-patterns.md - Naming conventions

## ThorLabs Standards
- **Naming**: `thorlabs-{service}{number}-{region}`
- **Location**: `eastus2` (primary)
- **Tags**: Environment='Lab', Project='ThorLabs', AutoShutdown_Time='19:00'
- **Architecture**: Foundation → Security → Compute → Data

## Usage
```
Create a new Bicep template for [service] that follows ThorLabs patterns
```

## References
- Microsoft Bicep documentation
- Azure MCP server for schema validation
- Existing ThorLabs templates for patterns
