# SaaS database schema

MariaDB is the platform database. GenieACS MongoDB remains the separate ACS operational store. PR #1 documents the logical schema; it does not apply migrations to production.

## Core tables
| Table | Important columns / purpose |
|---|---|
| tenants | id, slug, name, status, created_at |
| tenant_settings | tenant_id, setting_key, setting_value |
| tenant_acs_assignments | tenant_id, acs_instance_id, status |
| acs_instances | id, name, mode, nbi_base_url_ref, status; secrets referenced, not stored in plaintext |
| tenant_ingress_ports | id, tenant_id, hostname, port, status, allocated_at, released_at |
| users | id, email, password_hash, status |
| roles | id, tenant_id nullable, name |
| permissions | id, permission_key, description |
| user_roles | user_id, role_id, tenant_id |
| devices | id, tenant_id, genieacs_device_id, serial_number, oui, product_class, manufacturer, model, status, last_inform_at |
| device_enrollments | id, tenant_id, device_fingerprint, verification_method, status, verified_by, verified_at |
| device_events | id, tenant_id, device_id, event_type, payload_redacted, occurred_at |
| device_metrics | id, tenant_id, device_id, metric_key, metric_value, measured_at |
| provisioning_profiles | id, tenant_id, name, profile_json, status |
| plans | id, name, billing_period, device_quota, price_amount, currency, status |
| subscriptions | id, tenant_id, plan_id, status, starts_at, ends_at |
| invoices | id, tenant_id, subscription_id, invoice_number, total_amount, currency, status, due_at |
| invoice_items | id, invoice_id, description, quantity, unit_amount, total_amount |
| payments | id, tenant_id, invoice_id, provider, external_reference, amount, currency, status, paid_at |
| usage_daily | id, tenant_id, usage_date, active_devices, total_informs |
| api_keys | id, tenant_id, key_hash, scopes, expires_at, revoked_at |
| audit_logs | id, tenant_id nullable, actor_user_id, action, resource_type, resource_id, request_id, metadata_redacted, created_at |
| notifications | id, tenant_id, channel, recipient_ref, template_key, status |
| webhooks | id, tenant_id, endpoint_url, secret_ref, event_types, status |

## Constraints and indexes
- Unique: tenants.slug; tenant_ingress_ports.hostname; tenant_ingress_ports.port; users.email (or scoped uniqueness if product policy later requires it).
- Unique device ownership: devices.genieacs_device_id; serial number uniqueness must account for vendor/OUI and legitimate replacement cases.
- Foreign keys from tenant-owned records to tenants; use restrictive deletion for billing/audit records.
- Index tenant_id with common lookup columns, e.g. (tenant_id, status), (tenant_id, device_id, occurred_at), (tenant_id, measured_at).
- Use DECIMAL for monetary values; never floating point.
- Store timestamps in UTC; render in tenant/user timezone.
- Do not store plaintext passwords, API keys, NBI credentials or webhook secrets.

## Isolation invariant
For every tenant-scoped query, tenant_id comes from the authenticated server-side context. A client-provided tenant_id is never authoritative. Device data imported from GenieACS must be reconciled with a trusted enrollment/ownership record before it becomes visible.
