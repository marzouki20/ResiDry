CREATE TABLE document_verifications (
 id VARCHAR(36) PRIMARY KEY,
 account_id VARCHAR(36) NOT NULL REFERENCES accounts(id),
 fingerprint VARCHAR(64) NOT NULL,
 result TEXT NOT NULL,
 expires_at TIMESTAMP NOT NULL
);
CREATE TABLE application_supporting_documents (
 application_id VARCHAR(36) NOT NULL REFERENCES driver_applications(id),
 side VARCHAR(32) NOT NULL,
 mime_type VARCHAR(50) NOT NULL,
 content_base64 TEXT NOT NULL,
 PRIMARY KEY (application_id, side)
);
ALTER TABLE driver_applications ADD COLUMN verification_id VARCHAR(36);
ALTER TABLE driver_applications ADD COLUMN borrowed BOOLEAN NOT NULL DEFAULT FALSE;
