# Trueqer: Flutter & OpenAPI 3.0 Integration Guide

Welcome to the Trueqer client engineering guide! This document is specifically written for the **Flutter mobile development team**. If this is your first time working with **OpenAPI (formerly Swagger)** or **Contract-First development**, don't worry—this guide covers everything step by step, from core architectural principles to running local mocks and generating fully typed Dart models and API services automatically.

---

## Table of Contents
1. [Core Architectural Rules: The "Dumb Client" Principle](#1-core-architectural-rules-the-dumb-client-principle)
2. [What is OpenAPI 3.0 and Why Are We Using It?](#2-what-is-openapi-30-and-why-are-we-using-it)
3. [Rapid UI Development with the Prism Mock Server](#3-rapid-ui-development-with-the-prism-mock-server)
4. [Auto-Generating Dart / Flutter API Code](#4-auto-generating-dart--flutter-api-code)
5. [Connecting Flutter to the API Gateway](#5-connecting-flutter-to-the-api-gateway)
6. [Trueqer Endpoints & Core User Flows](#6-trueqer-endpoints--core-user-flows)
   - [A. Public Profiles & Reviews](#a-public-profiles--reviews)
   - [B. Discovery & Geospatial Search (Uber H3)](#b-discovery--geospatial-search-uber-h3)
   - [C. Swap Lifecycle State Machine](#c-swap-lifecycle-state-machine)
   - [D. Guided Transactional Chat & Guardrails](#d-guided-transactional-chat--guardrails)
   - [E. Proof-of-Meeting Dynamic TOTP QR Code](#e-proof-of-meeting-dynamic-totp-qr-code)
   - [F. Blind Reviews](#f-blind-reviews)
7. [HTTP Status Codes & Error Handling](#7-http-status-codes--error-handling)
8. [Frequently Asked Questions (FAQ)](#8-frequently-asked-questions-faq)

---

## 1. Core Architectural Rules: The "Dumb Client" Principle

Before writing UI code, it is critical to understand Trueqer's security and system architecture:

```
+--------------------------------------------------------------------+
|                         FLUTTER MOBILE APP                         |
|   (Android 10+ / iOS 15+ Presentation Layer - "DUMB CLIENT")       |
|    - Renders UI, animations, forms, and camera QR scanner          |
|    - ZERO direct database connections                              |
|    - ZERO database credentials stored in client bundle             |
+--------------------------------------------------------------------+
                                |
                                | HTTPS + Bearer JWT Token
                                v
+--------------------------------------------------------------------+
|                      SERVERLESS API GATEWAY                        |
|        (Firebase Cloud Functions / Node.js + TypeScript)           |
|    - Enforces authentication (Google OAuth2 / Apple Sign-In)       |
|    - Enforces finite state machines & ACID transactions            |
|    - Validates TOTP Proof-of-Meeting tokens & GPS proximity        |
+--------------------------------------------------------------------+
                                |
                                | Private VPC / Managed Pool
                                v
+--------------------------------------------------------------------+
|                           MySQL DATABASE                           |
|       (Users, Skills, User_Skills, Swaps, Messages, Reviews)       |
|    - Isolated from the internet (Accessible only by Gateway)       |
|    - GDPR immediate physical cascade purge                         |
+--------------------------------------------------------------------+
```

### Critical Rules:
1. **Zero Direct Database Exposure**: The mobile app NEVER connects directly to MySQL. Direct connections from mobile devices would leak database credentials, bypass validation rules, and cause concurrency race conditions.
2. **All Business Logic is Server-Enforced**: State transitions (e.g. `PENDING` -> `MATCHED` -> `SCHEDULED` -> `COMPLETED`) cannot be manipulated on the client.
3. **Geospatial Privacy ([REQ-06])**: Continuous background GPS tracking is strictly forbidden. The mobile app never requests or stores exact home addresses. Location is generalized via Uber H3 hexagonal cells and 2-decimal coordinates (~1.1 km area).

---

## 2. What is OpenAPI 3.0 and Why Are We Using It?

### The Problem with Traditional Development
In traditional workflows, frontend developers must wait for backend developers to finish writing endpoints and databases, or rely on outdated PDF/Postman docs. When field names change (e.g. `user_id` vs `userId`), the mobile app crashes at runtime.

### The Solution: Contract-First with OpenAPI 3.0
OpenAPI 3.0 is a standardized, machine-readable YAML specification located at:
`docs/api/openapi.yaml`

It defines:
- **Every endpoint URL and HTTP verb** (`GET`, `POST`, `PATCH`, `DELETE`)
- **Required headers** (`Authorization: Bearer <token>`)
- **Query and path parameters** (with types and validation limits)
- **JSON request payloads and response bodies** (with exact field names and types)
- **All possible error codes** (400, 401, 403, 404, 409, 422)

**Key Benefit**: You can use automated CLI tools to generate 100% type-safe Dart classes directly from this file. No more writing JSON parsers by hand!

---

## 3. Rapid UI Development with the Prism Mock Server

You do **not** have to wait for the backend or database to be deployed to start building Flutter screens!

Trueqer includes a pre-configured **Prism Mock Server** that reads `docs/api/openapi.yaml` and simulates the entire backend locally.

### How to Start the Mock Server
In the root directory of the repository:

```bash
# Start the mock server on port 4010
npm run mock:api
```

You will see Prism start:
```
[PRISM] ℹ  info      GET        http://127.0.0.1:4010/api/v1/users/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d/public-profile
[PRISM] ℹ  info      POST       http://127.0.0.1:4010/api/v1/swaps/request
[PRISM] ℹ  info      PATCH      http://127.0.0.1:4010/api/v1/swaps/3e4b5c6d-7a8b-9c0d-1e2f-3a4b5c6d7e8f/status
[PRISM] ℹ  info      POST       http://127.0.0.1:4010/api/v1/meetings/validate-qr
```

### Pointing Your Flutter App to the Local Mock Server

When running on emulators or simulators, use the appropriate localhost loopback IP:

| Environment | Mock Server URL in Flutter |
| :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:4010` (Android routes `10.0.2.2` to host machine) |
| **iOS Simulator** | `http://127.0.0.1:4010` |
| **Physical Device (USB/Wi-Fi)** | `http://<YOUR_LOCAL_IP>:4010` (e.g. `http://192.168.1.50:4010`) |

---

## 4. Auto-Generating Dart / Flutter API Code

Instead of manually typing Dart models (`class PublicProfileResponse { ... }`) and `fromJson` / `toJson` mappers, generate them automatically!

### Option A: Using OpenAPI Generator CLI (Recommended for Clean Dio Services)

Install the OpenAPI generator CLI (already available via npm or Homebrew):
```bash
npx @openapitools/openapi-generator-cli generate \
  -i docs/api/openapi.yaml \
  -g dart-dio \
  -o mobile/lib/core/network/generated \
  --additional-properties=pubName=trueqer_api,nullableFields=true
```

This creates:
- Fully typed data models for all requests and responses.
- `DefaultApi` / domain API classes utilizing `dio`.
- Built-in JSON serialization and deserialization.

---

### Option B: Using `swagger_dart_code_generator` (Flutter-Native via `build_runner`)

If your Flutter project prefers `build_runner`, follow these steps:

#### Step 1: Add dependencies to `mobile/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.9.0
  swagger_dart_code_generator: ^2.13.0
```

#### Step 2: Configure `build.yaml` in `/mobile`
Create `mobile/build.yaml`:
```yaml
targets:
  $default:
    builders:
      swagger_dart_code_generator:
        options:
          input_folder: '../docs/api/'
          output_folder: 'lib/core/network/generated/'
          use_path_for_request_names: true
```

#### Step 3: Run the code generator
```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

All models, serializers, and client methods will be instantly generated in `lib/core/network/generated/`.

---

## 5. Connecting Flutter to the API Gateway

Here is an idiomatic example of setting up a `Dio` HTTP client with an **Auth Interceptor** to automatically attach Bearer JWT tokens:

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        // Switch between Local Mock, Local Emulator, or Cloud Gateway
        baseUrl: kDebugMode 
          ? 'http://10.0.2.2:4010' // Android Emulator pointing to Prism
          : 'https://us-central1-trueqer-app.cloudfunctions.net/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Retrieve current token from secure storage or Firebase Auth
          final String? idToken = await _getAuthToken();
          if (idToken != null) {
            options.headers['Authorization'] = 'Bearer $idToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Centralized error handling
          debugPrint('API Error [${error.response?.statusCode}]: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    // In production, fetch from FirebaseAuth.instance.currentUser?.getIdToken()
    // For local mock testing with Prism:
    return 'user_1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d';
  }
}
```

---

## 6. Trueqer Endpoints & Core User Flows

### A. Public Profiles & Reviews

#### 1. Fetching Public Profile
- **Endpoint**: `GET /api/v1/users/{user_id}/public-profile`
- **Purpose**: Displays user bio, approximate zone, reputation ratings, and offered/desired skills.
- **Privacy Notice**: Private data (email, phone, exact residence) is **never** included.

```dart
Future<PublicProfileResponse> fetchUserProfile(String userId) async {
  final response = await ApiClient().dio.get(
    '/api/v1/users/$userId/public-profile',
    queryParameters: {
      'requester_lat': -34.60, // Current user approximate lat
      'requester_lng': -58.38, // Current user approximate lng
    },
  );
  return PublicProfileResponse.fromJson(response.data);
}
```

#### 2. Paginated Reviews
- **Endpoint**: `GET /api/v1/users/{user_id}/reviews?page=1&limit=10`
- **Purpose**: Fetches revealed full-text reviews without bloating the main profile response.

---

### B. Discovery & Geospatial Search (Uber H3)

- **Endpoint**: `GET /api/v1/search`
- **Parameters**: `category`, `skill_id`, `h3_index`, `query`, `page`, `limit`
- **Behavior**: Users with active availability status (`is_available = true`) are prioritized at the top.

---

### C. Swap Lifecycle State Machine

The skill swap lifecycle is governed by a finite state machine:

```
[ PENDING ] 
    │
    ├── Receiver Rejects ───────────► [ REJECTED ]
    ├── Either Party Cancels ───────► [ CANCELLED ]
    │
    └── Receiver Accepts (Double Opt-In [REQ-08, REQ-09])
            │
            ▼
       [ MATCHED ] ◄── Chat Channel Unlocks!
            │
            ├── Either Party Cancels ──► [ CANCELLED ]
            │
            └── Light Scheduling Agreement ([REQ-11, REQ-12])
                    │
                    ▼
              [ SCHEDULED ] ◄── Skills Frozen! Dynamic TOTP Secret Initialized
                    │
                    ├── Either Party Cancels ──► [ CANCELLED ]
                    │
                    └── In-Person Proof-of-Meeting QR Scanned ([REQ-13])
                            │
                            ▼
                      [ COMPLETED ] ◄── Reviews Unlocked (Blind Mode)
```

#### Proposing a Swap:
```dart
Future<void> proposeSwap({
  required String targetUserId,
  required String offeredSkillId,
  required String requestedSkillId,
  required String message,
}) async {
  await ApiClient().dio.post(
    '/api/v1/swaps/request',
    data: {
      'target_user_id': targetUserId,
      'offered_skill_id': offeredSkillId,
      'requested_skill_id': requestedSkillId,
      'initial_message': message, // Max 300 chars!
    },
  );
}
```

#### Scheduling the Meeting (Light Scheduling Modal):
```dart
Future<void> scheduleMeeting({
  required String swapId,
  required DateTime dateTime,
  required String locationName,
}) async {
  await ApiClient().dio.patch(
    '/api/v1/swaps/$swapId/status',
    data: {
      'action': 'SCHEDULE',
      'scheduled_at': dateTime.toUtc().toIso8601String(),
      'meeting_location': locationName,
    },
  );
}
```

---

### D. Guided Transactional Chat & Guardrails

The chat feature operates under strict guardrails:
1. **Double Opt-In Lock**: Requests to `/api/v1/swaps/{swap_id}/messages` return `403 CHAT_LOCKED` until the swap reaches `MATCHED` or `SCHEDULED`.
2. **Length Guardrail**: Free text messages have a strict upper limit of **300 characters**.
3. **No Media**: Sending audio notes or images is strictly blocked at the API Gateway.
4. **Action Widgets**: Chat supports Quick-Reply Chips and Light Scheduling Action Cards.

---

### E. Proof-of-Meeting Dynamic TOTP QR Code

When users meet in person, they complete the swap cryptographically:

1. **Host Screen (Displaying Dynamic QR)**:
   - Call `GET /api/v1/swaps/{swap_id}/qr-token`
   - Render the `totp_token` in a QR widget (`qr_flutter`).
   - Re-fetch or regenerate every 30 seconds.

2. **Guest Screen (Scanning QR)**:
   - Scan the host's screen with `mobile_scanner`.
   - Acquire current one-time GPS coordinates.
   - Send `POST /api/v1/meetings/validate-qr`:
   ```dart
   final response = await ApiClient().dio.post(
     '/api/v1/meetings/validate-qr',
     data: {
       'swap_id': swapId,
       'totp_token': scannedToken,
       'latitude': userLocation.latitude,
       'longitude': userLocation.longitude,
     },
   );
   // Returns HTTP 200 { "success": true, "status": "COMPLETED" }
   ```

---

### F. Blind Reviews

Once a swap is `COMPLETED`, both users can submit a review:
- **Endpoint**: `POST /api/v1/swaps/{swap_id}/reviews`
- **Fields**: `rating` (1 to 5), `comment` (10-500 chars), `skill_confirmed` (boolean).
- **Blind Window**: The review is **hidden** until both users have submitted or 48 hours have passed.

---

## 7. HTTP Status Codes & Error Handling

All error responses from Trueqer API Gateway follow a consistent schema:

```json
{
  "code": "VALIDATION_FAILED",
  "message": "Request payload failed schema validation.",
  "status": 422,
  "errors": [
    {
      "field": "initial_message",
      "message": "String must contain at most 300 character(s)"
    }
  ]
}
```

| HTTP Status | Error Code | What it Means for the Flutter UI |
| :--- | :--- | :--- |
| **400 Bad Request** | `BAD_REQUEST` | Syntax or parameter issue. Check input types. |
| **401 Unauthorized** | `UNAUTHORIZED` | Token expired or missing. Redirect to Login screen. |
| **403 Forbidden** | `CHAT_LOCKED` / `FORBIDDEN` | Show lock badge. User cannot chat until swap is `MATCHED`. |
| **404 Not Found** | `NOT_FOUND` | User or swap does not exist. Show empty state. |
| **409 Conflict** | `INVALID_STATE_TRANSITION` | Swap state changed on server (e.g. cancelled by partner). Refresh screen state. |
| **422 Unprocessable** | `VALIDATION_FAILED` | Show red validation helper text on the corresponding form input. |

---

## 8. Frequently Asked Questions (FAQ)

### Q1: Can we connect Flutter directly to MySQL with a Dart MySQL driver?
**NO.** Absolutely not. Connecting Flutter directly to a relational database exposes database passwords inside the app binary (which can be reverse-engineered in minutes), prevents connection pooling, and bypasses the ACID transactions and business logic of the serverless gateway.

### Q2: What happens if a user loses internet connectivity while generating the Proof-of-Meeting QR code?
The QR code uses RFC 6238 TOTP with a shared secret negotiated during scheduling. The guest device only needs a momentary connection to submit the token and GPS coordinates to the gateway.

### Q3: How do we test error states with the mock server?
Prism Mock Server allows requesting specific HTTP status codes via headers:
```dart
options.headers['Prefer'] = 'status=409'; // Forces Prism to return HTTP 409 Conflict
```

---

*Document maintained by the Trueqer Architecture Team. For questions or contract proposals, reach out in the team communication channel.*
