# Trueqer: System Architecture & Data Model

## 1. System Overview

Trueqer is a peer-to-peer two-sided market platform for swapping skills and knowledge without monetary exchange.

```mermaid
flowchart TD
    Client["Flutter Mobile App (iOS / Android)<br/>Dumb Client Presentation Layer"]
    Gateway["Serverless API Gateway (TypeScript / Node.js)<br/>OAuth2 Auth • State Machine • Rate Limits"]
    MySQL[("MySQL 8.0+ Database<br/>ACID Transactions • H3 Geocells • Strict Isolation")]
    Firebase["Firebase Services<br/>Google & Apple OAuth2 ID Tokens"]

    Client -- "HTTPS + Bearer JWT" --> Gateway
    Client -. "OAuth2 Login" .-> Firebase
    Gateway -- "ACID Connection Pool" --> MySQL
    Gateway -. "Verify Token" .-> Firebase
```

---

## 2. Relational Data Model (MySQL 8.0+)

The relational model implements strict 3NF structure, ACID transactional consistency, and cascade purges for GDPR:

```mermaid
erDiagram
    users ||--o{ user_skills : "has"
    skills ||--o{ user_skills : "categorized in"
    users ||--o{ swaps : "requester"
    users ||--o{ swaps : "receiver"
    skills ||--o{ swaps : "offered skill"
    skills ||--o{ swaps : "requested skill"
    swaps ||--o{ messages : "contains"
    users ||--o{ messages : "sends"
    swaps ||--o{ reviews : "evaluated in"
    users ||--o{ reviews : "writes"
    users ||--o{ reviews : "receives"

    users {
        varchar user_id PK
        enum oauth_provider
        varchar display_name
        varchar avatar_url
        varchar bio
        boolean is_available
        decimal average_rating
        int total_swaps
        decimal fuzzy_lat
        decimal fuzzy_lng
        varchar h3_index
    }

    skills {
        varchar skill_id PK
        varchar name UK
        varchar category
    }

    user_skills {
        varchar user_skill_id PK
        varchar user_id FK
        varchar skill_id FK
        enum skill_type "OFFERED | DESIRED"
        enum proficiency_level
    }

    swaps {
        varchar swap_id PK
        varchar requester_id FK
        varchar receiver_id FK
        varchar offered_skill_id FK
        varchar requested_skill_id FK
        enum status "PENDING|MATCHED|SCHEDULED|COMPLETED|CANCELLED|REJECTED"
        timestamp scheduled_at
        timestamp completed_at
        varchar meeting_location
        varchar qr_secret
    }

    messages {
        varchar message_id PK
        varchar swap_id FK
        varchar sender_id FK
        enum message_type "TEXT|QUICK_REPLY|ACTION_WIDGET"
        varchar content "Max 300 chars"
        json widget_payload
    }

    reviews {
        varchar review_id PK
        varchar swap_id FK
        varchar reviewer_id FK
        varchar reviewee_id FK
        tinyint rating "1 to 5"
        text comment
        boolean skill_confirmed
        boolean is_revealed "Blind review"
        timestamp revealed_at
    }
```

---

## 3. Privacy & Geospatial Architecture ([REQ-06])

- **No Continuous Tracking**: Background GPS monitoring is strictly prohibited.
- **No Exact Coordinates Stored or Shared**: User residence coordinates are truncated to 2 decimal places (`fuzzy_lat`, `fuzzy_lng`, ~1.1 km precision).
- **Uber H3 Indexing**: Location resolution is indexed using Uber H3 hexagonal cells. Neighbor search queries run as simple SQL lookups:
  ```sql
  SELECT * FROM users WHERE h3_index IN ('882a1072b7fffff', '882a1072b5fffff') AND is_available = TRUE;
  ```

---

## 4. Finite State Machine & Proof-of-Meeting Flow

```mermaid
stateDiagram-v2
    [*] --> PENDING: POST /api/v1/swaps/request
    PENDING --> REJECTED: PATCH /api/v1/swaps/:id/status (REJECT)
    PENDING --> CANCELLED: PATCH /api/v1/swaps/:id/status (CANCEL)
    PENDING --> MATCHED: PATCH /api/v1/swaps/:id/status (ACCEPT - Double Opt-In)
    
    MATCHED --> CANCELLED: PATCH /api/v1/swaps/:id/status (CANCEL)
    MATCHED --> SCHEDULED: PATCH /api/v1/swaps/:id/status (SCHEDULE - Light Scheduling)
    
    SCHEDULED --> CANCELLED: PATCH /api/v1/swaps/:id/status (CANCEL)
    SCHEDULED --> COMPLETED: POST /api/v1/meetings/validate-qr (Dynamic TOTP + Geofence)
    
    COMPLETED --> [*]: Blind Reviews & Async Reputation Update
    REJECTED --> [*]
    CANCELLED --> [*]
```

---

## 5. Security & Isolation Matrix

| Capability | Mobile Client (Flutter) | API Gateway (Serverless) | MySQL Database |
| :--- | :---: | :---: | :---: |
| Direct DB Connection | ❌ Strictly Prohibited |  VPC Connection Pool | N/A |
| Business Logic Enforcement | ❌ Dumb presentation |  Authoritative | ❌ Enforces schema/FKs |
| TOTP Validation | ❌ Camera Scan Only |  Cryptographic HMAC | ❌ Raw Secret Storage |
| GDPR Cascade Purge | ❌ HTTP Trigger |  ACID Transaction |  ON DELETE CASCADE |
| State Transition Control | ❌ Request Only |  Strict Guards | ❌ State column |
