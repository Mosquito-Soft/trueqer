# Trueqer Documentation Hub

This directory contains technical architecture, OpenAPI specifications, and integration guides for the Trueqer peer-to-peer skill swap platform.

## Directory Structure

```
docs/
├── api/
│   └── openapi.yaml                  # OpenAPI 3.0.3 contract specification
├── FLUTTER_OPENAPI_GUIDE.md          # Step-by-step OpenAPI onboarding and Dio guide for Flutter
├── GIT_AND_MOBILE_WORKFLOW.md        # Monorepo integration instructions and Git branching strategy
├── ARCHITECTURE_OVERVIEW.md          # System architecture, Mermaid diagrams, and database rationale
└── README.md                         # Documentation index (this file)
```

## Quick Reference Links

- **[Flutter & OpenAPI Integration Guide](./FLUTTER_OPENAPI_GUIDE.md)**: Designed for Flutter developers using OpenAPI for the first time. Explains the "Dumb Client" architecture, local Prism mock server setup, Dart code generation (via `dio` or `build_runner`), state machine handling, and dynamic TOTP Proof-of-Meeting flows.
- **[Git Branching Workflow & Mobile Integration](./GIT_AND_MOBILE_WORKFLOW.md)**: Detailed instructions on the `main` -> `dev` -> `feature/*` workflow, PR checklists, and how the Flutter team imports their external project into `/mobile`.
- **[Mobile Team Onboarding (`mobile/README.md`)](../mobile/README.md)**: Quickstart guide located directly inside the mobile folder.
- **[System Architecture & Data Model](./ARCHITECTURE_OVERVIEW.md)**: High-level architectural diagrams, MySQL 3NF schema overview, Uber H3 geospatial privacy rules, and security isolation matrix.
- **[OpenAPI 3.0.3 Specification](./api/openapi.yaml)**: Complete YAML contract with all endpoints, request bodies, query parameters, RFC 7807/custom error schemas, and realistic examples.

## Key Developer Commands

From repository root:

```bash
# 1. Run local Prism Mock Server for Flutter frontend development
npm run mock:api

# 2. Validate OpenAPI 3.0.3 specification with Redocly
npm run validate:openapi

# 3. Autogenerate TypeScript types from the OpenAPI contract
npm run generate:types

# 4. Run the API Gateway in development mode
npm run dev
```
