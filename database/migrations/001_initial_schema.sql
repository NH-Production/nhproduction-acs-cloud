-- NHProduction ACS Cloud logical schema baseline.
-- REVIEW ONLY: do not apply to production. Validate against the selected application version first.
-- Target: MariaDB 10.6+, InnoDB, utf8mb4.
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS tenants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(80) NOT NULL,
  name VARCHAR(190) NOT NULL,
  status ENUM('pending','active','suspended','archived') NOT NULL DEFAULT 'pending',
  timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Jakarta',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tenants_slug (slug),
  KEY idx_tenants_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(190) NOT NULL,
  status ENUM('invited','active','disabled') NOT NULL DEFAULT 'invited',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NULL,
  role_key VARCHAR(80) NOT NULL,
  label VARCHAR(120) NOT NULL,
  is_platform_role TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_tenant_key (tenant_id, role_key),
  CONSTRAINT fk_roles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  permission_key VARCHAR(120) NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_key (permission_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  tenant_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_role_scope (user_id, role_id, tenant_id),
  KEY idx_user_roles_tenant (tenant_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT,
  CONSTRAINT fk_ur_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS acs_instances (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  instance_key VARCHAR(80) NOT NULL,
  label VARCHAR(160) NOT NULL,
  mode ENUM('shared') NOT NULL DEFAULT 'shared',
  nbi_base_url_ref VARCHAR(255) NOT NULL,
  status ENUM('active','maintenance','disabled') NOT NULL DEFAULT 'active',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_acs_instance_key (instance_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_acs_assignments (
  tenant_id BIGINT UNSIGNED NOT NULL,
  acs_instance_id BIGINT UNSIGNED NOT NULL,
  status ENUM('active','disabled') NOT NULL DEFAULT 'active',
  assigned_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (tenant_id),
  KEY idx_taa_instance (acs_instance_id),
  CONSTRAINT fk_taa_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_taa_instance FOREIGN KEY (acs_instance_id) REFERENCES acs_instances(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_ingress_ports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  hostname VARCHAR(253) NOT NULL,
  tcp_port SMALLINT UNSIGNED NOT NULL,
  status ENUM('reserved','active','disabled','released') NOT NULL DEFAULT 'reserved',
  allocated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  released_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ingress_hostname (hostname),
  UNIQUE KEY uq_ingress_port (tcp_port),
  UNIQUE KEY uq_ingress_tenant (tenant_id),
  CONSTRAINT fk_ingress_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT chk_ingress_port CHECK (tcp_port BETWEEN 1024 AND 65535)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS plans (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  plan_key VARCHAR(80) NOT NULL,
  name VARCHAR(120) NOT NULL,
  billing_period ENUM('monthly','quarterly','yearly') NOT NULL DEFAULT 'monthly',
  device_quota INT UNSIGNED NOT NULL,
  price_amount DECIMAL(14,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'IDR',
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (id),
  UNIQUE KEY uq_plans_key (plan_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subscriptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NOT NULL,
  status ENUM('trialing','active','past_due','suspended','cancelled','expired') NOT NULL,
  starts_at DATETIME(3) NOT NULL,
  ends_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_subscriptions_tenant_status (tenant_id, status),
  CONSTRAINT fk_sub_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_sub_plan FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  subscription_id BIGINT UNSIGNED NULL,
  invoice_number VARCHAR(80) NOT NULL,
  total_amount DECIMAL(14,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'IDR',
  status ENUM('draft','issued','paid','void','overdue') NOT NULL DEFAULT 'draft',
  due_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_number (invoice_number),
  KEY idx_invoices_tenant_status (tenant_id, status),
  CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoice_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invoice_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(12,2) NOT NULL DEFAULT 1,
  unit_amount DECIMAL(14,2) NOT NULL,
  total_amount DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_invoice_items_invoice (invoice_id),
  CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(80) NOT NULL DEFAULT 'manual',
  external_reference VARCHAR(190) NULL,
  amount DECIMAL(14,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'IDR',
  status ENUM('pending','verified','failed','refunded') NOT NULL DEFAULT 'pending',
  paid_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_payments_tenant_status (tenant_id, status),
  KEY idx_payments_invoice (invoice_id),
  CONSTRAINT fk_payments_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS devices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  genieacs_device_id VARCHAR(255) NOT NULL,
  serial_number VARCHAR(190) NOT NULL,
  oui VARCHAR(16) NULL,
  product_class VARCHAR(120) NULL,
  manufacturer VARCHAR(160) NULL,
  model VARCHAR(160) NULL,
  status ENUM('pending','active','blocked','revoked') NOT NULL DEFAULT 'pending',
  last_inform_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_devices_genieacs_id (genieacs_device_id),
  KEY idx_devices_tenant_status (tenant_id, status),
  KEY idx_devices_tenant_serial (tenant_id, serial_number),
  CONSTRAINT fk_devices_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_enrollments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NULL,
  device_fingerprint VARCHAR(255) NOT NULL,
  verification_method VARCHAR(80) NOT NULL,
  status ENUM('discovered','pending','verified','rejected','revoked') NOT NULL DEFAULT 'discovered',
  verified_by BIGINT UNSIGNED NULL,
  verified_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_enrollment_tenant_status (tenant_id, status),
  CONSTRAINT fk_enroll_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_enroll_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE RESTRICT,
  CONSTRAINT fk_enroll_verifier FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  payload_redacted JSON NULL,
  occurred_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_events_tenant_device_time (tenant_id, device_id, occurred_at),
  CONSTRAINT fk_events_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_events_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_metrics (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NOT NULL,
  metric_key VARCHAR(120) NOT NULL,
  metric_value VARCHAR(255) NULL,
  measured_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_metrics_tenant_device_time (tenant_id, device_id, measured_at),
  CONSTRAINT fk_metrics_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_metrics_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS provisioning_profiles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  profile_json JSON NOT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'inactive',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_profiles_tenant_status (tenant_id, status),
  CONSTRAINT fk_profiles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usage_daily (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  usage_date DATE NOT NULL,
  active_devices INT UNSIGNED NOT NULL DEFAULT 0,
  total_informs BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usage_tenant_date (tenant_id, usage_date),
  CONSTRAINT fk_usage_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_keys (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(120) NOT NULL,
  key_hash CHAR(64) NOT NULL,
  scopes JSON NOT NULL,
  expires_at DATETIME(3) NULL,
  revoked_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_api_key_hash (key_hash),
  KEY idx_api_keys_tenant (tenant_id),
  CONSTRAINT fk_api_keys_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  action VARCHAR(120) NOT NULL,
  resource_type VARCHAR(120) NOT NULL,
  resource_id VARCHAR(190) NULL,
  request_id VARCHAR(100) NULL,
  metadata_redacted JSON NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_audit_tenant_time (tenant_id, created_at),
  KEY idx_audit_actor_time (actor_user_id, created_at),
  CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  channel VARCHAR(40) NOT NULL,
  recipient_ref VARCHAR(190) NOT NULL,
  template_key VARCHAR(120) NOT NULL,
  status ENUM('queued','sent','failed') NOT NULL DEFAULT 'queued',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_notifications_tenant_status (tenant_id, status),
  CONSTRAINT fk_notifications_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS webhooks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  endpoint_url VARCHAR(2048) NOT NULL,
  secret_ref VARCHAR(255) NOT NULL,
  event_types JSON NOT NULL,
  status ENUM('active','disabled') NOT NULL DEFAULT 'disabled',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_webhooks_tenant_status (tenant_id, status),
  CONSTRAINT fk_webhooks_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
