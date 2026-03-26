
INSERT INTO "auth"."audit_log_entries" ("instance_id", "id", "payload", "created_at", "ip_address") VALUES
	('00000000-0000-0000-0000-000000000000', 'cbfe840c-84fb-421a-b407-151264153109', '{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"test@user.com","user_id":"dadc2e13-3ca2-4021-b1de-7de4a4857d6f","user_phone":""}}', '2025-07-01 00:00:56.65496+00', ''),
	('00000000-0000-0000-0000-000000000000', '7297df90-d550-4d12-a9e5-a137d92f2ee9', '{"action":"login","actor_id":"dadc2e13-3ca2-4021-b1de-7de4a4857d6f","actor_username":"test@user.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}', '2025-07-01 00:01:48.948639+00', '');


INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
  ('00000000-0000-0000-0000-000000000000', 'dadc2e13-3ca2-4021-b1de-7de4a4857d6f', 'authenticated', 'authenticated', 'test@user.com', '$2a$10$tApDe/yUjmGxgQoTjeVAP.bPmTi.BjcN./TiU23LyqbyllP5oxnfK', '2025-07-01 00:00:56.655976+00', NULL, '', NULL, '', NULL, '', '', NULL, '2025-07-01 00:01:48.948952+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2025-07-01 00:00:56.646963+00', '2025-07-01 00:01:48.952538+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
  ('00000000-0000-0000-0000-000000000000', 'e3c21171-051b-49a8-a62f-741bd129a60b', 'authenticated', 'authenticated', 'test3@user.com', '$2a$10$tApDe/yUjmGxgQoTjeVAP.bPmTi.BjcN./TiU23LyqbyllP5oxnfK', '2025-07-01 00:00:56.655976+00', NULL, '', NULL, '', NULL, '', '', NULL, '2025-07-01 00:01:48.948952+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2025-07-01 00:00:56.646963+00', '2025-07-01 00:01:48.952538+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
  ('00000000-0000-0000-0000-000000000000', 'dfdc2e13-3ca2-4021-b1de-7de4a4857d6f', 'authenticated', 'authenticated', 'test2@user.com', '$2a$10$tApDe/yUjmGxgQoTjeVAP.bPmTi.BjcN./TiU23LyqbyllP5oxnfK', '2025-07-01 00:00:56.655976+00', NULL, '', NULL, '', NULL, '', '', NULL, '2025-07-01 00:01:48.948952+00', '{"provider": "email", "providers": ["email"]}', '{"email_verified": true}', NULL, '2025-07-01 00:00:56.646963+00', '2025-07-01 00:01:48.952538+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
  ('dadc2e13-3ca2-4021-b1de-7de4a4857d6f', 'dadc2e13-3ca2-4021-b1de-7de4a4857d6f', '{"sub": "dadc2e13-3ca2-4021-b1de-7de4a4857d6f", "email": "test@user.com", "email_verified": false, "phone_verified": false}', 'email', '2025-07-01 00:00:56.653718+00', '2025-07-01 00:00:56.653771+00', '2025-07-01 00:00:56.653771+00', '192970b5-0498-4eea-9d38-572300d3b407'),
  ('e3c21171-051b-49a8-a62f-741bd129a60b', 'e3c21171-051b-49a8-a62f-741bd129a60b', '{"sub": "e3c21171-051b-49a8-a62f-741bd129a60b", "email": "test3@user.com", "email_verified": false, "phone_verified": false}', 'email', '2025-07-01 00:00:56.653718+00', '2025-07-01 00:00:56.653771+00', '2025-07-01 00:00:56.653771+00', '292970b5-0498-4eea-9d38-572300d3b408'),
  ('dfdc2e13-3ca2-4021-b1de-7de4a4857d6f', 'dfdc2e13-3ca2-4021-b1de-7de4a4857d6f', '{"sub": "dfdc2e13-3ca2-4021-b1de-7de4a4857d6f", "email": "test2@user.com", "email_verified": false, "phone_verified": false}', 'email', '2025-07-01 00:02:56.653718+00', '2025-07-01 00:02:56.653771+00', '2025-07-01 00:02:56.653771+00', '392970b5-0498-4eea-9d38-572300d3b409');

-- Delete any existing roles for seed users (trigger may have created them)
DELETE FROM "public"."user_roles" WHERE user_id IN (
  'dadc2e13-3ca2-4021-b1de-7de4a4857d6f',
  'e3c21171-051b-49a8-a62f-741bd129a60b',
  'dfdc2e13-3ca2-4021-b1de-7de4a4857d6f'
);

-- Grant admin role to test@user.com (the main test admin account)
INSERT INTO "public"."user_roles" ("user_id", "role") VALUES
  ('dadc2e13-3ca2-4021-b1de-7de4a4857d6f', 'admin');

-- Grant user role to other test users
INSERT INTO "public"."user_roles" ("user_id", "role") VALUES
  ('e3c21171-051b-49a8-a62f-741bd129a60b', 'user'),
  ('dfdc2e13-3ca2-4021-b1de-7de4a4857d6f', 'user');

