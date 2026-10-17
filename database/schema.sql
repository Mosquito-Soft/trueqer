-- ==============================================================================
-- Trueqer Database DDL Schema (MySQL 8.0+)
-- Architecture: Community Skill Swap (Peer-to-Peer Two-Sided Market)
-- Compliance: ACID Transactions, GDPR Cascade Purge ([REQ-03]),
--             Fuzzy Location & Uber H3 Hexagonal Indexing ([REQ-06]),
--             Dumb-Client Isolation (Access exclusively via Serverless API Gateway).
-- ==============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- 1. Table: users
-- Core identity and aggregated reputation table.
-- Sensitive PII (emails, phone numbers, exact residential coordinates) is strictly
-- excluded from this schema or stored outside public scopes.
-- Location follows fuzzy truncation (2 decimal places ~1.1km) and H3 indexing.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id VARCHAR(36) NOT NULL COMMENT 'UUID linked to OAuth2 provider subject ID [REQ-01]',
    oauth_provider ENUM('GOOGLE', 'APPLE') NOT NULL COMMENT 'Identity provider',
    oauth_subject_id VARCHAR(255) NOT NULL COMMENT 'Unique external subject ID from provider',
    display_name VARCHAR(100) NOT NULL COMMENT 'Public user display name [REQ-02]',
    avatar_url VARCHAR(512) NULL COMMENT 'Public CDN URL for avatar image',
    bio VARCHAR(500) NULL COMMENT 'Brief free-text biography and personal interests',
    is_available BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Active availability status for swap discovery',
    
    -- Aggregated reputation metrics (Asynchronously recalculated via triggers / workers)
    average_rating DECIMAL(3, 2) NOT NULL DEFAULT 0.00 COMMENT 'Average review score (1.00 - 5.00)',
    total_swaps INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total count of completed swaps',
    total_reviews INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total count of revealed reviews',
    punctuality_score DECIMAL(3, 2) NOT NULL DEFAULT 0.00 COMMENT 'Aggregated punctuality rating',
    
    -- Geospatial Privacy ([REQ-06]): Truncated coordinates (2 decimals) & Uber H3 geocell
    fuzzy_lat DECIMAL(5, 2) NULL COMMENT 'Approximate latitude truncated to 2 decimals (~1.1km)',
    fuzzy_lng DECIMAL(5, 2) NULL COMMENT 'Approximate longitude truncated to 2 decimals (~1.1km)',
    h3_index VARCHAR(15) NULL COMMENT 'Uber H3 hexagonal index (resolution 7 or 8) for fast neighborhood queries',
    zone_name VARCHAR(100) NULL COMMENT 'Public general neighborhood name (e.g. Palermo Soho, Downtown)',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_oauth (oauth_provider, oauth_subject_id),
    INDEX idx_users_h3_index (h3_index),
    INDEX idx_users_availability (is_available, average_rating DESC),
    INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User profiles and reputation aggregates';

-- ------------------------------------------------------------------------------
-- 2. Table: skills
-- Standardized master catalog of skills and knowledge domains for fast filtering.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS skills;
CREATE TABLE skills (
    skill_id VARCHAR(36) NOT NULL COMMENT 'UUID identifier for standardized skill',
    name VARCHAR(100) NOT NULL COMMENT 'Unique skill name (e.g. Acoustic Guitar, Figma UX Design)',
    category VARCHAR(100) NOT NULL COMMENT 'Domain category (e.g. Music, Design, Tech, Languages)',
    description VARCHAR(255) NULL COMMENT 'Standard description of the skill scope',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (skill_id),
    UNIQUE KEY uq_skills_name (name),
    INDEX idx_skills_category (category),
    INDEX idx_skills_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Master catalog of standardized skills';

-- ------------------------------------------------------------------------------
-- 3. Table: user_skills
-- Hybrid competency model ([REQ-04]) explicitly decoupling skills offered to teach
-- from skills desired to learn.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS user_skills;
CREATE TABLE user_skills (
    user_skill_id VARCHAR(36) NOT NULL COMMENT 'UUID primary key',
    user_id VARCHAR(36) NOT NULL COMMENT 'FK to users.user_id',
    skill_id VARCHAR(36) NOT NULL COMMENT 'FK to skills.skill_id',
    skill_type ENUM('OFFERED', 'DESIRED') NOT NULL COMMENT 'Explicitly separates offered vs desired skills [REQ-04]',
    proficiency_level ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT') NOT NULL DEFAULT 'INTERMEDIATE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_skill_id),
    UNIQUE KEY uq_user_skill_type (user_id, skill_id, skill_type),
    INDEX idx_user_skills_user (user_id, skill_type),
    INDEX idx_user_skills_skill (skill_id, skill_type),
    
    -- GDPR Cascade Delete: Purging a user automatically purges all their skill relationships [REQ-03]
    CONSTRAINT fk_user_skills_user FOREIGN KEY (user_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_user_skills_skill FOREIGN KEY (skill_id) 
        REFERENCES skills (skill_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User skills categorized as offered or desired';

-- ------------------------------------------------------------------------------
-- 4. Table: swaps
-- Transactional core of bilateral skill exchanges.
-- Both users simultaneously teach and learn, prohibiting learner_id/teacher_id naming.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS swaps;
CREATE TABLE swaps (
    swap_id VARCHAR(36) NOT NULL COMMENT 'UUID primary key',
    requester_id VARCHAR(36) NOT NULL COMMENT 'User initiating the swap proposal [REQ-07]',
    receiver_id VARCHAR(36) NOT NULL COMMENT 'Target user receiving the proposal [REQ-08]',
    offered_skill_id VARCHAR(36) NOT NULL COMMENT 'Skill requester offers to teach',
    requested_skill_id VARCHAR(36) NOT NULL COMMENT 'Skill requester desires to learn in return',
    
    -- Finite state machine controlled exclusively by serverless API Gateway
    status ENUM('PENDING', 'MATCHED', 'SCHEDULED', 'COMPLETED', 'CANCELLED', 'REJECTED') 
        NOT NULL DEFAULT 'PENDING' COMMENT 'Server-controlled state machine status',
    
    scheduled_at TIMESTAMP NULL COMMENT 'Agreed in-person session timestamp (Light Scheduling)',
    completed_at TIMESTAMP NULL COMMENT 'Timestamp when dynamic TOTP QR code was validated in person',
    meeting_location VARCHAR(255) NULL COMMENT 'Agreed public venue/zone name from Light Scheduling',
    cancellation_reason VARCHAR(255) NULL COMMENT 'Reason if swap was cancelled',
    
    -- Ephemeral secret for dynamic TOTP Proof-of-Meeting QR rotation (RFC 6238)
    qr_secret VARCHAR(64) NULL COMMENT 'Base32 secret for TOTP dynamic verification',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (swap_id),
    INDEX idx_swaps_requester (requester_id, status),
    INDEX idx_swaps_receiver (receiver_id, status),
    INDEX idx_swaps_status (status),
    INDEX idx_swaps_scheduled_at (scheduled_at),
    
    -- GDPR Cascade: User deletion removes their swap participation records
    CONSTRAINT fk_swaps_requester FOREIGN KEY (requester_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_swaps_receiver FOREIGN KEY (receiver_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_swaps_offered_skill FOREIGN KEY (offered_skill_id) 
        REFERENCES skills (skill_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_swaps_requested_skill FOREIGN KEY (requested_skill_id) 
        REFERENCES skills (skill_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_swaps_different_users CHECK (requester_id <> receiver_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bilateral skill swap transactions and state machine';

-- ------------------------------------------------------------------------------
-- 5. Table: messages
-- Guided transactional chat for swaps.
-- Guardrails: locked until swap reaches MATCHED status [REQ-09, REQ-10].
-- Max 300 chars, no images/voice notes, supports Quick-Replies & Action Widgets.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
    message_id VARCHAR(36) NOT NULL COMMENT 'UUID primary key',
    swap_id VARCHAR(36) NOT NULL COMMENT 'FK to swaps.swap_id',
    sender_id VARCHAR(36) NOT NULL COMMENT 'FK to users.user_id',
    message_type ENUM('TEXT', 'QUICK_REPLY', 'ACTION_WIDGET') 
        NOT NULL DEFAULT 'TEXT' COMMENT 'Message subtype for guided interaction',
    content VARCHAR(300) NOT NULL COMMENT 'Text content bounded by strict 300 char limit. Media strictly prohibited.',
    widget_payload JSON NULL COMMENT 'Structured payload for Light Scheduling proposals or interactive chips',
    is_system BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag for automated server status messages',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (message_id),
    INDEX idx_messages_swap_created (swap_id, created_at),
    INDEX idx_messages_sender (sender_id),
    
    CONSTRAINT fk_messages_swap FOREIGN KEY (swap_id) 
        REFERENCES swaps (swap_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Guided transactional swap chat messages';

-- ------------------------------------------------------------------------------
-- 6. Table: reviews
-- Independent blind review table.
-- Ratings are never stored directly in swaps nor exposed in unrevealed state.
-- Hidden until both participants submit or 48 hours elapse.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
    review_id VARCHAR(36) NOT NULL COMMENT 'UUID primary key',
    swap_id VARCHAR(36) NOT NULL COMMENT 'FK to swaps.swap_id',
    reviewer_id VARCHAR(36) NOT NULL COMMENT 'User writing the evaluation',
    reviewee_id VARCHAR(36) NOT NULL COMMENT 'User receiving the evaluation',
    rating TINYINT UNSIGNED NOT NULL COMMENT 'Numerical rating 1 to 5 stars',
    comment TEXT NOT NULL COMMENT 'Qualitative feedback regarding session experience',
    skill_confirmed BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Confirmation that agreed skill was practiced',
    
    -- Blind review window control (48-hour expiration or mutual submission)
    is_revealed BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Hidden until mutual submission or 48h expiration',
    revealed_at TIMESTAMP NULL COMMENT 'Timestamp when review became publicly visible',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (review_id),
    UNIQUE KEY uq_swap_reviewer (swap_id, reviewer_id),
    INDEX idx_reviews_swap (swap_id),
    INDEX idx_reviews_reviewee (reviewee_id, is_revealed),
    INDEX idx_reviews_revealed_timer (is_revealed, created_at),
    
    CONSTRAINT fk_reviews_swap FOREIGN KEY (swap_id) 
        REFERENCES swaps (swap_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewee FOREIGN KEY (reviewee_id) 
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reviews_different_parties CHECK (reviewer_id <> reviewee_id),
    CONSTRAINT chk_reviews_rating_range CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Independent blind reviews and ratings';

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------------------
-- SEED DATA: Standardized Skill Catalog for MVP Testing
-- ------------------------------------------------------------------------------
INSERT INTO skills (skill_id, name, category, description) VALUES
('c4a7e912-32a1-432d-98e6-123456789abc', 'UI/UX Design with Figma', 'Design & Creative', 'User interface design, wireframing, and interactive prototyping'),
('f8b9d012-76e3-4921-b452-987654321def', 'Acoustic Guitar Basics', 'Music & Audio', 'Basic open chords, strumming patterns, and fingerpicking foundations'),
('a1b2c3d4-e5f6-7a8b-9c0d-111111111111', 'Conversational Spanish', 'Languages', 'Daily practical vocabulary, conversational fluency, and pronunciation'),
('a2b3c4d5-e6f7-8a9b-0c1d-222222222222', 'Conversational English', 'Languages', 'ESL dialogue practice, idiom mastery, and business communication'),
('b1c2d3e4-f5a6-7b8c-9d0e-333333333333', 'Portrait & Street Photography', 'Photography', 'Camera manual exposure, composition rules, and natural lighting'),
('c1d2e3f4-a5b6-7c8d-9e0f-444444444444', 'Introduction to Python Programming', 'Technology', 'Syntax, data structures, algorithms, and practical automation scripts'),
('d1e2f3a4-b5c6-7d8e-9f0a-555555555555', 'Sourdough Bread Baking', 'Culinary Arts', 'Starter maintenance, fermentation timing, shaping, and Dutch oven baking'),
('e1f2a3b4-c5d6-7e8f-9a0b-666666666666', 'Vinyasa Yoga & Mindfulness', 'Health & Wellness', 'Breath control, flow postures, flexibility routines, and meditation')
ON DUPLICATE KEY UPDATE name=VALUES(name);
