CREATE TABLE accounts (
 id VARCHAR(36) PRIMARY KEY, name VARCHAR(150) NOT NULL,
 email VARCHAR(254) NOT NULL UNIQUE, password_hash VARCHAR(100) NOT NULL,
 role VARCHAR(20) NOT NULL CHECK(role IN ('DRIVER','ADMIN','RESIDENT','LAUNDRY')),
 phone VARCHAR(12), created_at TIMESTAMP NOT NULL
);
CREATE TABLE auth_sessions (
 token_hash VARCHAR(64) PRIMARY KEY, account_id VARCHAR(36) NOT NULL REFERENCES accounts(id),
 expires_at TIMESTAMP NOT NULL
);
CREATE TABLE driver_applications (
 id VARCHAR(36) PRIMARY KEY, account_id VARCHAR(36) NOT NULL UNIQUE REFERENCES accounts(id),
 status VARCHAR(30) NOT NULL CHECK(status IN ('DRAFT','SUBMITTED','UNDER_REVIEW','CORRECTION_REQUESTED','APPROVED','REJECTED')),
 vehicle_type VARCHAR(30), declared_kg DECIMAL(10,2), reserve_kg DECIMAL(10,2), zones TEXT NOT NULL,
 consent BOOLEAN NOT NULL, revision INTEGER NOT NULL,
 ai_status VARCHAR(30) NOT NULL, ai_result TEXT,
 confirmed_payload_kg DECIMAL(10,2), confirmed_reserve_kg DECIMAL(10,2),
 review_reason VARCHAR(2000), submitted_at TIMESTAMP, updated_at TIMESTAMP NOT NULL
);
CREATE TABLE application_documents (
 application_id VARCHAR(36) NOT NULL REFERENCES driver_applications(id), side VARCHAR(10) NOT NULL,
 mime_type VARCHAR(30) NOT NULL, content_base64 TEXT NOT NULL,
 PRIMARY KEY(application_id,side), CHECK(side IN ('FRONT','BACK'))
);
CREATE TABLE application_events (
 id VARCHAR(36) PRIMARY KEY, application_id VARCHAR(36) NOT NULL REFERENCES driver_applications(id),
 actor_id VARCHAR(36) NOT NULL REFERENCES accounts(id), event_type VARCHAR(40) NOT NULL,
 revision INTEGER NOT NULL, details TEXT NOT NULL, occurred_at TIMESTAMP NOT NULL
);
