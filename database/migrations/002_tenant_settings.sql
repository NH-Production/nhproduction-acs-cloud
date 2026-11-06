-- Tenant-scoped settings for NHProduction ACS Cloud.
-- Apply only after review in an isolated staging database.
CREATE TABLE IF NOT EXISTS tenant_settings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL,
  setting_key VARCHAR(120) NOT NULL,
  setting_value JSON NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tenant_settings_key (tenant_id, setting_key),
  CONSTRAINT fk_tenant_settings_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
