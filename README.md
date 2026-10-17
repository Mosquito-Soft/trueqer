# Trueqer (Community Skill Swap)

A peer-to-peer two-sided market platform for exchanging skills and knowledge without monetary transactions.

---

## Architecture & Monorepo Overview

Trueqer is structured as a unified monorepo following strict separation of concerns and the **"Dumb Client" principle**:

- **[`mobile/`](./mobile/)**: Presentation layer built in Flutter for Android 10+ and iOS 15+. Operates with zero direct database connections.
- **[`functions/`](./functions/)**: Serverless API Gateway deployed with Node.js and TypeScript on Firebase Cloud Functions. Owns business logic, finite state machines, and ACID transactions.
- **[`database/`](./database/)**: MySQL 8.0 DDL schema, indexes (Uber H3 geocells), and GDPR cascade deletion scripts.
- **[`docs/`](./docs/)**: OpenAPI 3.0.3 contract specifications, architectural diagrams, and developer integration guides.

---

## Documentation Quick Links

| Document | Description |
| :--- | :--- |
| **[Flutter & OpenAPI Integration Guide](./docs/FLUTTER_OPENAPI_GUIDE.md)** | Step-by-step onboarding for the mobile team (OpenAPI, Prism mock, Dart codegen). |
| **[Git Branching & Mobile Integration Guide](./docs/GIT_AND_MOBILE_WORKFLOW.md)** | `main` / `dev` / `feature/*` workflow and instructions to import Flutter code into `/mobile`. |
| **[System Architecture & Data Model](./docs/ARCHITECTURE_OVERVIEW.md)** | System diagrams, MySQL ERD, H3 privacy model, and security isolation matrix. |
| **[OpenAPI 3.0.3 Contract (`openapi.yaml`)](./docs/api/openapi.yaml)** | Source of truth for all endpoints, request/response schemas, and error models. |

---

## Quickstart

### 1. Run Local Prism Mock Server (For Flutter UI Development)
Allows the Flutter team to build and test screens against realistic mocked responses immediately:
```bash
npm run mock:api
```
- Android Emulator endpoint: `http://10.0.2.2:4010`
- iOS Simulator endpoint: `http://127.0.0.1:4010`

### 2. Validate OpenAPI Contract
```bash
npm run validate:openapi
```

### 3. Generate TypeScript Types from OpenAPI
```bash
npm run generate:types
```

### 4. Start Serverless API Gateway Locally
```bash
npm run dev
```

---

## Git Workflow Summary

1. Always branch off `dev`: `git checkout -b feature/<task-name> dev`
2. Never commit directly to `main` or `dev`.
3. Submit Pull Requests targeting `dev`.
4. CI runs automated tests on PR before merging.
