-- FreeLLMAPI web (Supabase/Postgres) schema. Generated from the final SQLite migrations.
-- Timestamps stay TEXT in UTC (YYYY-MM-DD HH24:MI:SS) so existing string logic keeps working.

CREATE TABLE api_keys (
      id BIGSERIAL PRIMARY KEY,
      platform TEXT NOT NULL,
      label TEXT NOT NULL DEFAULT '',
      encrypted_key TEXT NOT NULL,
      iv TEXT NOT NULL,
      auth_tag TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'unknown',
      enabled BIGINT NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      last_checked_at TEXT
    , base_url TEXT, last_health_error TEXT, model_scope_json TEXT, proxy_encrypted TEXT, proxy_iv TEXT, proxy_auth_tag TEXT, monthly_request_cap BIGINT NOT NULL DEFAULT 0, monthly_token_cap BIGINT NOT NULL DEFAULT 0, group_label TEXT, last_healthy_at TEXT);

CREATE TABLE backups (
      id BIGSERIAL PRIMARY KEY,
      filename TEXT NOT NULL,
      filepath TEXT,
      filesize BIGINT NOT NULL,
      is_full BIGINT NOT NULL DEFAULT 1,
      source TEXT NOT NULL DEFAULT 'manual',
      created_at TEXT NOT NULL,
      tables_json TEXT NOT NULL DEFAULT '[]'
    );

CREATE TABLE catalog_model_tombstones (
      kind TEXT NOT NULL DEFAULT 'chat',
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')), source TEXT NOT NULL DEFAULT 'user', reason TEXT,
      PRIMARY KEY (kind, platform, model_id)
    );

CREATE TABLE client_profiles (
      id BIGSERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      token_hash TEXT NOT NULL UNIQUE,
      encrypted_key TEXT NOT NULL,
      iv TEXT NOT NULL,
      auth_tag TEXT NOT NULL,
      system_prompt TEXT,
      enabled BIGINT NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      updated_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    );

CREATE TABLE cloudflare_neuron_usage (
      day TEXT NOT NULL,
      account_id TEXT NOT NULL,
      model_id TEXT NOT NULL,
      calls BIGINT NOT NULL DEFAULT 0,
      settled_calls BIGINT NOT NULL DEFAULT 0,
      input_tokens BIGINT NOT NULL DEFAULT 0,
      output_tokens BIGINT NOT NULL DEFAULT 0,
      neurons DOUBLE PRECISION NOT NULL DEFAULT 0,
      remote_neurons DOUBLE PRECISION,
      remote_checked_at_ms BIGINT,
      PRIMARY KEY (day, account_id, model_id)
    );

CREATE TABLE custom_model_tombstones (
      endpoint_scope TEXT NOT NULL,
      model_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      PRIMARY KEY (endpoint_scope, model_id)
    );

CREATE TABLE decision_requests (
      id BIGSERIAL PRIMARY KEY,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      model_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      key_id BIGINT,
      status TEXT NOT NULL CHECK (status IN ('ok', 'error')),
      latency_ms BIGINT NOT NULL DEFAULT 0,
      question_count BIGINT NOT NULL DEFAULT 0,
      input_tokens BIGINT NOT NULL DEFAULT 0,
      client_agent TEXT,
      error TEXT
    );

CREATE TABLE embedding_models (
      id BIGSERIAL PRIMARY KEY,
      family TEXT NOT NULL,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      display_name TEXT NOT NULL,
      dimensions BIGINT NOT NULL,
      max_input_tokens BIGINT,
      priority BIGINT NOT NULL DEFAULT 0,
      enabled BIGINT NOT NULL DEFAULT 1,
      quota_label TEXT NOT NULL DEFAULT '', key_id BIGINT,
      UNIQUE(platform, model_id)
    );

CREATE TABLE "models" (
      id BIGSERIAL PRIMARY KEY,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      display_name TEXT NOT NULL,
      intelligence_rank BIGINT NOT NULL,
      speed_rank BIGINT NOT NULL,
      size_label TEXT NOT NULL DEFAULT '',
      rpm_limit BIGINT,
      rpd_limit BIGINT,
      tpm_limit BIGINT,
      tpd_limit BIGINT,
      monthly_token_budget TEXT NOT NULL DEFAULT '',
      context_window BIGINT,
      enabled BIGINT NOT NULL DEFAULT 1,
      supports_vision BIGINT NOT NULL DEFAULT 0,
      key_id BIGINT,
      supports_tools BIGINT NOT NULL DEFAULT 0,
      paid_input_per_m DOUBLE PRECISION,
      paid_output_per_m DOUBLE PRECISION,
      source TEXT NOT NULL DEFAULT 'catalog',
      endpoint_scope TEXT NOT NULL DEFAULT '',
      UNIQUE(platform, model_id, endpoint_scope)
    );

CREATE TABLE fallback_config (
      id BIGSERIAL PRIMARY KEY,
      model_db_id BIGINT NOT NULL REFERENCES models(id),
      priority BIGINT NOT NULL,
      enabled BIGINT NOT NULL DEFAULT 1,
      UNIQUE(model_db_id)
    );

CREATE TABLE idempotency_claims (
      id BIGSERIAL PRIMARY KEY,
      key_hash TEXT NOT NULL UNIQUE,
      request_fingerprint TEXT NOT NULL,
      response_status BIGINT NOT NULL,
      response_body TEXT NOT NULL,
      execution_id TEXT,
      created_at_ms BIGINT NOT NULL,
      expires_at_ms BIGINT NOT NULL
    );

CREATE TABLE key_monthly_usage (
      key_id BIGINT NOT NULL,
      month TEXT NOT NULL,
      requests BIGINT NOT NULL DEFAULT 0,
      tokens BIGINT NOT NULL DEFAULT 0,
      PRIMARY KEY (key_id, month)
    );

CREATE TABLE "media_models" (
      id BIGSERIAL PRIMARY KEY,
      platform TEXT NOT NULL, model_id TEXT NOT NULL, display_name TEXT NOT NULL,
      modality TEXT NOT NULL, priority BIGINT NOT NULL DEFAULT 0,
      enabled BIGINT NOT NULL DEFAULT 1, quota_label TEXT NOT NULL DEFAULT '',
      key_id BIGINT, meta_json TEXT
      , endpoint_scope TEXT NOT NULL DEFAULT '',
      UNIQUE(platform, model_id, endpoint_scope)
    );

CREATE TABLE migrations (
    id BIGSERIAL PRIMARY KEY,
    filename TEXT NOT NULL UNIQUE,
    applied_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
  );

CREATE TABLE model_monthly_usage (
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      month TEXT NOT NULL,
      tokens BIGINT NOT NULL DEFAULT 0,
      PRIMARY KEY (platform, model_id, month)
    );

CREATE TABLE model_overrides (
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      overrides_json TEXT NOT NULL DEFAULT '{}',
      updated_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      PRIMARY KEY (platform, model_id)
    );

CREATE TABLE model_probe_status (
    platform TEXT NOT NULL,
    model_id TEXT NOT NULL,
    endpoint_scope TEXT,
    key_id BIGINT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unknown',
    last_probed_at TEXT,
    last_error TEXT,
    latency_ms BIGINT,
    PRIMARY KEY (platform, model_id, endpoint_scope, key_id)
  );

CREATE TABLE playground_conversations (
      id BIGSERIAL PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      messages_json TEXT NOT NULL DEFAULT '[]',
      model TEXT,
      system_prompt TEXT,
      created_at_ms BIGINT NOT NULL,
      updated_at_ms BIGINT NOT NULL
    );

CREATE TABLE profiles (
      id BIGSERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '',
      color TEXT NOT NULL DEFAULT '#6366f1',
      type TEXT NOT NULL DEFAULT 'custom',
      is_favorite BIGINT NOT NULL DEFAULT 0,
      sort_order BIGINT NOT NULL DEFAULT 0,
      auto_sort TEXT,
      layout_config TEXT,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    , auto_include_new_models BIGINT NOT NULL DEFAULT 1, routing_strategy TEXT);

CREATE TABLE profile_models (
      id BIGSERIAL PRIMARY KEY,
      profile_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      model_db_id BIGINT NOT NULL REFERENCES models(id) ON DELETE CASCADE,
      priority BIGINT NOT NULL,
      enabled BIGINT NOT NULL DEFAULT 1,
      UNIQUE(profile_id, model_db_id)
    );

CREATE TABLE provider_quota_observations (
      id TEXT PRIMARY KEY,
      platform TEXT NOT NULL,
      key_id BIGINT NOT NULL,
      provider_account_id TEXT,
      model_id TEXT,
      quota_pool_key TEXT NOT NULL,
      metric TEXT NOT NULL,
      status_code BIGINT,
      limit_value BIGINT,
      remaining_value BIGINT,
      reset_at TEXT,
      retry_after_ms BIGINT,
      reset_strategy TEXT NOT NULL DEFAULT 'unknown',
      source TEXT NOT NULL DEFAULT 'probe',
      confidence DOUBLE PRECISION NOT NULL DEFAULT 0,
      notes TEXT,
      raw_json TEXT,
      endpoint TEXT,
      observed_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    );

CREATE TABLE provider_quota_state (
      platform TEXT NOT NULL,
      key_id BIGINT NOT NULL,
      quota_pool_key TEXT NOT NULL,
      metric TEXT NOT NULL,
      limit_value BIGINT,
      remaining_value BIGINT,
      reset_at TEXT,
      reset_strategy TEXT NOT NULL DEFAULT 'unknown',
      source TEXT NOT NULL DEFAULT 'probe',
      confidence DOUBLE PRECISION NOT NULL DEFAULT 0,
      notes TEXT,
      observed_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      updated_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      PRIMARY KEY (platform, key_id, quota_pool_key, metric)
    );

CREATE TABLE quirks (
      id BIGSERIAL PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      severity TEXT NOT NULL DEFAULT 'info',
      created_at_ms BIGINT NOT NULL,
      updated_at_ms BIGINT NOT NULL
    );

CREATE TABLE quirk_targets (
      id BIGSERIAL PRIMARY KEY,
      quirk_id BIGINT NOT NULL REFERENCES quirks(id) ON DELETE CASCADE,
      platform TEXT,
      model_glob TEXT
    );

CREATE TABLE rate_limit_cooldowns (
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      key_id BIGINT NOT NULL,
      expires_at_ms BIGINT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')), source TEXT NOT NULL DEFAULT 'heuristic', set_at_ms BIGINT,
      PRIMARY KEY (platform, model_id, key_id)
    );

CREATE TABLE rate_limit_usage (
      id BIGSERIAL PRIMARY KEY,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      key_id BIGINT NOT NULL,
      kind TEXT NOT NULL CHECK (kind IN ('request', 'tokens')),
      tokens BIGINT NOT NULL DEFAULT 0,
      created_at_ms BIGINT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    );

CREATE TABLE requests (
      id BIGSERIAL PRIMARY KEY,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      key_id BIGINT,
      status TEXT NOT NULL,
      input_tokens BIGINT NOT NULL DEFAULT 0,
      output_tokens BIGINT NOT NULL DEFAULT 0,
      latency_ms BIGINT NOT NULL DEFAULT 0,
      error TEXT,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    , ttfb_ms BIGINT, requested_model TEXT, request_type TEXT NOT NULL DEFAULT 'chat', client_ip TEXT, client_user_agent TEXT, served_model TEXT, client_agent TEXT, caller TEXT, model_db_id BIGINT, failure_attribution TEXT, media_model_db_id BIGINT);

CREATE TABLE request_attempts (
      id BIGSERIAL PRIMARY KEY,
      request_id BIGINT NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
      ordinal BIGINT NOT NULL,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      key_ordinal BIGINT NOT NULL,
      outcome TEXT NOT NULL,
      start_offset_ms BIGINT NOT NULL DEFAULT 0,
      duration_ms BIGINT NOT NULL DEFAULT 0
    , error_summary TEXT, key_label TEXT);

CREATE TABLE request_hourly (
        hour TEXT PRIMARY KEY,
        total_requests BIGINT NOT NULL DEFAULT 0,
        success_count BIGINT NOT NULL DEFAULT 0,
        error_count BIGINT NOT NULL DEFAULT 0,
        input_tokens BIGINT NOT NULL DEFAULT 0,
        output_tokens BIGINT NOT NULL DEFAULT 0
      );

CREATE TABLE response_cache (
      cache_key TEXT PRIMARY KEY,
      body_json TEXT NOT NULL,
      platform TEXT NOT NULL,
      model_id TEXT NOT NULL,
      key_id BIGINT,
      prompt_tokens BIGINT NOT NULL,
      completion_tokens BIGINT NOT NULL,
      hit_count BIGINT NOT NULL DEFAULT 0,
      created_at_ms BIGINT NOT NULL,
      last_hit_at_ms BIGINT,
      expires_at_ms BIGINT NOT NULL
    );

CREATE TABLE search_requests (
      id BIGSERIAL PRIMARY KEY,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      engine_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      key_id BIGINT,
      status TEXT NOT NULL CHECK (status IN ('ok', 'error')),
      latency_ms BIGINT NOT NULL DEFAULT 0,
      result_count BIGINT NOT NULL DEFAULT 0,
      client_agent TEXT,
      error TEXT
    );

CREATE TABLE server_logs (
      id BIGINT PRIMARY KEY,
      level TEXT CHECK(level IN ('warn','error')),
      source TEXT,
      provider TEXT,
      model TEXT,
      event TEXT,
      request_id TEXT,
      message TEXT NOT NULL,
      created_at_ms BIGINT NOT NULL
    );

CREATE TABLE users (
      id BIGSERIAL PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    );

CREATE TABLE sessions (
      token_hash TEXT PRIMARY KEY,
      user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      expires_at_ms BIGINT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS'))
    );

CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );

CREATE TABLE url_tokens (
      id BIGSERIAL PRIMARY KEY,
      token_hash TEXT NOT NULL UNIQUE,
      label TEXT NOT NULL DEFAULT '',
      token_prefix TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (to_char(now() at time zone 'utc','YYYY-MM-DD HH24:MI:SS')),
      last_used_at TEXT,
      revoked_at TEXT
    );

CREATE INDEX idx_api_keys_platform ON api_keys(platform);

CREATE INDEX idx_catalog_model_tombstones_platform_model
      ON catalog_model_tombstones(platform, model_id);

CREATE INDEX idx_decision_requests_created_at ON decision_requests(created_at);

CREATE INDEX idx_decision_requests_model_created ON decision_requests(model_id, created_at);

CREATE INDEX idx_embedding_models_key_id ON embedding_models(key_id);

CREATE INDEX idx_idempotency_claims_expires
      ON idempotency_claims(expires_at_ms);

CREATE INDEX idx_media_models_key_id ON media_models(key_id);

CREATE INDEX idx_model_probe_status_probed_at
    ON model_probe_status(last_probed_at);

CREATE INDEX idx_models_endpoint_scope
      ON models(endpoint_scope) WHERE endpoint_scope <> '';

CREATE INDEX idx_playground_conversations_updated
      ON playground_conversations(updated_at_ms DESC);

CREATE INDEX idx_provider_quota_observations_created_at
      ON provider_quota_observations(created_at);

CREATE INDEX idx_provider_quota_observations_latest
      ON provider_quota_observations(platform, key_id, quota_pool_key, metric, observed_at DESC, created_at DESC);

CREATE INDEX idx_provider_quota_observations_platform ON provider_quota_observations(platform, key_id, observed_at);

CREATE INDEX idx_provider_quota_observations_reset_at ON provider_quota_observations(reset_at);

CREATE INDEX idx_provider_quota_state_platform ON provider_quota_state(platform, key_id, updated_at);

CREATE INDEX idx_provider_quota_state_reset_at ON provider_quota_state(reset_at);

CREATE INDEX idx_quirk_targets_quirk ON quirk_targets(quirk_id);

CREATE INDEX idx_quota_balance_observations
    ON provider_quota_observations(platform,key_id,quota_pool_key,metric,observed_at DESC,created_at DESC)
    WHERE remaining_value IS NOT NULL;

CREATE INDEX idx_rate_limit_cooldowns_expires ON rate_limit_cooldowns(expires_at_ms);

CREATE INDEX idx_rate_limit_usage_lookup ON rate_limit_usage(platform, model_id, key_id, kind, created_at_ms);

CREATE INDEX idx_request_attempts_request_id
      ON request_attempts(request_id, ordinal);

CREATE INDEX idx_request_hourly_hour ON request_hourly(hour);

CREATE INDEX idx_requests_client_agent_created ON requests(client_agent, created_at);

CREATE INDEX idx_requests_created_at ON requests(created_at);

CREATE INDEX idx_requests_created_latency
      ON requests(created_at, latency_ms);

CREATE INDEX idx_requests_key_id ON requests(key_id);

CREATE INDEX idx_requests_media_model_db_id ON requests(media_model_db_id);

CREATE INDEX idx_requests_model_db_id ON requests(model_db_id);

CREATE INDEX idx_requests_platform ON requests(platform);

CREATE INDEX idx_response_cache_expires
      ON response_cache(expires_at_ms);

CREATE INDEX idx_search_requests_created_at ON search_requests(created_at);

CREATE INDEX idx_search_requests_engine_created ON search_requests(engine_id, created_at);

CREATE INDEX idx_server_logs_created
      ON server_logs(created_at_ms, id);

CREATE INDEX idx_sessions_user ON sessions(user_id);

CREATE INDEX idx_url_tokens_active
      ON url_tokens(token_hash, revoked_at);




-- Monthly usage triggers (ported from SQLite). created_at is UTC text 'YYYY-MM-DD HH:MM:SS'.
CREATE OR REPLACE FUNCTION fn_requests_key_monthly_usage() RETURNS trigger AS $$
BEGIN
  IF NEW.key_id IS NOT NULL AND NEW.status = 'success' AND left(NEW.created_at, 7) ~ '^\d{4}-\d{2}$' THEN
    INSERT INTO key_monthly_usage (key_id, month, requests, tokens)
    VALUES (NEW.key_id, left(NEW.created_at, 7), 1, GREATEST(0, NEW.input_tokens) + GREATEST(0, NEW.output_tokens))
    ON CONFLICT (key_id, month) DO UPDATE SET
      requests = key_monthly_usage.requests + 1,
      tokens = key_monthly_usage.tokens + EXCLUDED.tokens;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS requests_key_monthly_usage ON requests;
CREATE TRIGGER requests_key_monthly_usage AFTER INSERT ON requests
  FOR EACH ROW EXECUTE FUNCTION fn_requests_key_monthly_usage();

CREATE OR REPLACE FUNCTION fn_requests_model_monthly_usage() RETURNS trigger AS $$
BEGIN
  IF NEW.request_type = 'chat' AND left(NEW.created_at, 7) ~ '^\d{4}-\d{2}$' THEN
    INSERT INTO model_monthly_usage (platform, model_id, month, tokens)
    VALUES (NEW.platform, NEW.model_id, left(NEW.created_at, 7), NEW.input_tokens + NEW.output_tokens)
    ON CONFLICT (platform, model_id, month) DO UPDATE SET
      tokens = model_monthly_usage.tokens + EXCLUDED.tokens;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS requests_model_monthly_usage ON requests;
CREATE TRIGGER requests_model_monthly_usage AFTER INSERT ON requests
  FOR EACH ROW EXECUTE FUNCTION fn_requests_model_monthly_usage();

-- Seed data (bundled catalog baseline)
INSERT INTO profiles (id,name,emoji,color,type,is_favorite,sort_order,auto_sort,layout_config,created_at,auto_include_new_models,routing_strategy) VALUES (1,'Default','⚙️','#6366f1','default',0,-1,NULL,NULL,'2026-11-15 07:15:59',1,NULL) ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (1,'google','gemini-2.5-pro','Gemini 2.5 Pro',14,8,'Large',5,50,250000,NULL,'~6M',1048576,0,1,NULL,1,1.25,10.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (2,'google','gemini-2.5-flash','Gemini 2.5 Flash',20,5,'Medium',10,20,250000,NULL,'~3M',1048576,1,1,NULL,1,0.3,2.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (3,'google','gemini-2.5-flash-lite','Gemini 2.5 Flash-Lite',26,3,'Medium',15,20,250000,NULL,'~3M',1048576,1,1,NULL,1,0.1,0.4,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (6,'openrouter','qwen/qwen3-coder:free','Qwen3 Coder (free)',2,9,'Medium',20,200,NULL,NULL,'~6M',1048576,1,0,NULL,1,0.22,1.8,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (7,'openrouter','z-ai/glm-4.5-air:free','GLM-4.5 Air (free)',8,9,'Medium',20,200,NULL,NULL,'~6M',131072,1,0,NULL,1,0.125,0.85,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (10,'cerebras','qwen-3-235b-a22b-instruct-2507','Qwen3 235B',3,1,'Medium',5,2400,30000,1000000,'~30M',8192,0,0,NULL,1,0.071,0.1,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (14,'mistral','mistral-large-latest','Mistral Large 3',14,8,'Medium',2,NULL,500000,NULL,'~50-100M',262144,1,0,NULL,1,0.5,1.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (15,'mistral','magistral-medium-latest','Magistral Medium',21,8,'Large',2,NULL,500000,NULL,'~50-100M',131072,1,0,NULL,1,2.0,5.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (16,'mistral','codestral-latest','Codestral',16,6,'Small',2,NULL,500000,NULL,'~50-100M',256000,1,0,NULL,1,0.3,0.9,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (17,'groq','llama-3.3-70b-versatile','Llama 3.3 70B',17,2,'Medium',30,1000,12000,100000,'~15M',131072,1,0,NULL,1,0.1,0.32,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (18,'groq','meta-llama/llama-4-scout-17b-16e-instruct','Llama 4 Scout',12,2,'Medium',30,1000,30000,1000000,'~30M',131072,1,1,NULL,1,0.08,0.3,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (19,'nvidia','meta/llama-3.1-70b-instruct','Llama 3.1 70B (NV)',17,6,'Medium',40,NULL,NULL,NULL,'~3M (1k credits)',131072,1,0,NULL,1,0.4,0.4,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (20,'cohere','command-r-plus-08-2024','Command R+ (08-2024)',27,11,'Medium',20,33,NULL,NULL,'~1-2M',131072,1,0,NULL,1,2.5,10.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (21,'cloudflare','@cf/meta/llama-3.3-70b-instruct-fp8-fast','Llama 3.3 70B fp8-fast (CF)',17,11,'Medium',NULL,NULL,NULL,NULL,'~18-45M',24000,1,0,NULL,1,0.1,0.32,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (23,'zhipu','glm-4.5-flash','GLM-4.5 Flash',24,4,'Large',NULL,NULL,NULL,1000000,'~30M',131072,1,0,NULL,1,0.06,0.4,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (38,'openrouter','nvidia/nemotron-3-super-120b-a12b:free','Nemotron 3 Super 120B (free)',22,9,'Large',20,200,NULL,NULL,'~6M',1000000,1,0,NULL,1,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (39,'openrouter','qwen/qwen3-next-80b-a3b-instruct:free','Qwen3-Next 80B (free)',3,9,'Large',20,200,NULL,NULL,'~6M',262144,1,0,NULL,1,0.09,1.1,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (44,'openrouter','nvidia/nemotron-3-nano-30b-a3b:free','Nemotron 3 Nano 30B (free)',23,9,'Medium',20,200,NULL,NULL,'~6M',262144,1,0,NULL,0,0.05,0.2,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (45,'openrouter','openai/gpt-oss-120b:free','GPT-OSS 120B (free)',6,9,'Large',20,200,NULL,NULL,'~6M',131072,1,0,NULL,1,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (46,'openrouter','openai/gpt-oss-20b:free','GPT-OSS 20B (free)',18,9,'Medium',20,200,NULL,NULL,'~6M',131072,1,0,NULL,1,0.029,0.14,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (47,'openrouter','meta-llama/llama-3.3-70b-instruct:free','Llama 3.3 70B (free)',17,9,'Medium',20,200,NULL,NULL,'~6M',131072,1,0,NULL,1,0.1,0.32,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (52,'groq','openai/gpt-oss-120b','GPT-OSS 120B (Groq)',6,2,'Large',30,1000,8000,200000,'~6M',131072,1,0,NULL,1,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (53,'groq','openai/gpt-oss-20b','GPT-OSS 20B (Groq)',18,2,'Medium',30,1000,8000,200000,'~6M',131072,1,0,NULL,1,0.029,0.14,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (54,'groq','qwen/qwen3-32b','Qwen3 32B (Groq)',19,2,'Medium',60,1000,6000,500000,'~15M',131072,1,0,NULL,1,0.08,0.28,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (55,'groq','llama-3.1-8b-instant','Llama 3.1 8B Instant',28,2,'Small',30,14400,6000,500000,'~15M',131072,1,0,NULL,1,0.02,0.03,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (56,'mistral','devstral-latest','Devstral',16,8,'Medium',2,NULL,500000,NULL,'~50-100M',262144,1,0,NULL,1,0.4,2.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (57,'mistral','mistral-medium-latest','Mistral Medium 3.5',14,8,'Large',2,NULL,500000,NULL,'~50-100M',131072,1,0,NULL,1,1.5,7.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (59,'cohere','command-a-03-2025','Command-A (03-2025)',27,11,'Medium',20,33,NULL,NULL,'~1-2M',131072,1,0,NULL,1,2.5,10.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (60,'cloudflare','@cf/openai/gpt-oss-120b','GPT-OSS 120B (CF)',6,11,'Large',NULL,NULL,NULL,NULL,'~18-45M',131072,1,0,NULL,1,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (61,'cloudflare','@cf/zai-org/glm-4.7-flash','GLM-4.7 Flash (CF)',10,11,'Large',NULL,NULL,NULL,NULL,'~18-45M',131072,1,0,NULL,1,0.06,0.4,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (62,'cloudflare','@cf/meta/llama-4-scout-17b-16e-instruct','Llama 4 Scout (CF)',12,11,'Medium',NULL,NULL,NULL,NULL,'~18-45M',131072,1,0,NULL,1,0.08,0.3,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (63,'cerebras','zai-glm-4.7','GLM-4.7 (Cerebras)',7,1,'Large',10,100,NULL,NULL,'~3M',8192,1,0,NULL,1,0.4,1.75,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (65,'cloudflare','@cf/qwen/qwen3-30b-a3b-fp8','Qwen3 30B-A3B fp8 (CF)',7,11,'Medium',NULL,NULL,NULL,NULL,'~18-45M',131072,1,0,NULL,1,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (66,'cloudflare','@cf/deepseek-ai/deepseek-r1-distill-qwen-32b','DeepSeek R1 Distill Qwen 32B (CF)',9,11,'Medium',NULL,NULL,NULL,NULL,'~3-5M',131072,1,0,NULL,1,0.29,0.29,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (67,'google','gemini-3.1-flash-lite-preview','Gemini 3.1 Flash-Lite Preview',18,3,'Large',15,20,250000,NULL,'~3M',1048576,1,1,NULL,1,0.25,1.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (68,'google','gemini-3-flash-preview','Gemini 3 Flash Preview',11,5,'Frontier',10,20,250000,NULL,'~3M',1048576,1,1,NULL,1,0.5,3.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (69,'google','gemini-3.1-pro-preview','Gemini 3.1 Pro Preview',1,8,'Frontier',5,20,250000,NULL,'~3M',1048576,0,1,NULL,1,2.0,12.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (70,'openrouter','google/gemma-4-31b-it:free','Gemma 4 31B (free)',19,9,'Large',20,200,NULL,NULL,'~6M',262144,1,0,NULL,0,0.12,0.37,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (71,'openrouter','liquid/lfm-2.5-1.2b-instruct:free','Liquid LFM 2.5 1.2B (free)',30,10,'Small',20,200,NULL,NULL,'~6M',32768,1,0,NULL,0,0.01,0.04,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (74,'openrouter','poolside/laguna-m.1:free','Poolside Laguna M.1 (free)',13,9,'Large',20,200,NULL,NULL,'~6M',131072,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (75,'openrouter','google/gemma-4-26b-a4b-it:free','Gemma 4 26B-A4B (free)',22,9,'Large',20,200,NULL,NULL,'~6M',262144,1,0,NULL,0,0.06,0.33,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (76,'openrouter','nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free','Nemotron 3 Nano 30B Reasoning (free)',23,9,'Medium',20,200,NULL,NULL,'~6M',262144,1,0,NULL,0,0.05,0.2,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (77,'openrouter','poolside/laguna-xs.2:free','Poolside Laguna XS.2 (free)',26,10,'Medium',20,200,NULL,NULL,'~6M',131072,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (78,'openrouter','nvidia/nemotron-nano-9b-v2:free','Nemotron Nano 9B v2 (free)',28,10,'Medium',20,200,NULL,NULL,'~6M',128000,1,0,NULL,0,0.04,0.16,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (79,'openrouter','liquid/lfm-2.5-1.2b-thinking:free','Liquid LFM 2.5 1.2B Thinking (free)',30,10,'Small',20,200,NULL,NULL,'~6M',32768,1,0,NULL,0,0.01,0.04,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (80,'zhipu','glm-4.7-flash','GLM-4.7 Flash',18,4,'Large',NULL,NULL,NULL,1000000,'~30M',131072,1,0,NULL,1,0.06,0.4,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (83,'cloudflare','@cf/moonshotai/kimi-k2.6','Kimi K2.6 (CF)',2,11,'Frontier',NULL,NULL,NULL,NULL,'~10-20M',262144,1,0,NULL,1,0.684,3.42,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (84,'cloudflare','@cf/ibm-granite/granite-4.0-h-micro','Granite 4.0 H Micro (CF)',29,11,'Small',NULL,NULL,NULL,NULL,'~5-10M',131072,1,0,NULL,0,0.017,0.112,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (85,'ollama','qwen3-coder:480b','Qwen3-Coder 480B (Ollama)',2,9,'Medium',NULL,NULL,NULL,NULL,'~5-10M',262144,1,0,NULL,1,0.22,1.8,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (86,'ollama','mistral-large-3:675b','Mistral Large 3 675B (Ollama)',3,9,'Medium',NULL,NULL,NULL,NULL,'~5-10M',131072,0,0,NULL,1,0.5,1.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (87,'ollama','deepseek-v3.2','DeepSeek V3.2 (Ollama)',4,9,'Large',NULL,NULL,NULL,NULL,'~5-10M',131072,0,0,NULL,1,0.229,0.343,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (88,'ollama','cogito-2.1:671b','Cogito 2.1 671B (Ollama)',4,9,'Frontier',NULL,NULL,NULL,NULL,'~5-10M',131072,1,0,NULL,0,1.25,1.25,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (89,'ollama','kimi-k2-thinking','Kimi K2 Thinking (Ollama)',5,9,'Frontier',NULL,NULL,NULL,NULL,'~5-10M',131072,0,0,NULL,1,0.6,2.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (90,'ollama','glm-4.7','GLM-4.7 (Ollama)',6,9,'Large',NULL,NULL,NULL,NULL,'~5-10M',131072,1,0,NULL,1,0.4,1.75,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (91,'ollama','gpt-oss:120b','GPT-OSS 120B (Ollama)',6,9,'Large',NULL,NULL,NULL,NULL,'~10-20M',131072,1,0,NULL,1,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (92,'ollama','devstral-2:123b','Devstral 2 123B (Ollama)',8,10,'Medium',NULL,NULL,NULL,NULL,'~10-20M',131072,1,0,NULL,1,0.4,2.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (93,'ollama','gpt-oss:20b','GPT-OSS 20B (Ollama)',18,10,'Medium',NULL,NULL,NULL,NULL,'~20-30M',131072,1,0,NULL,1,0.029,0.14,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (94,'ollama','gemma4:31b','Gemma 4 31B (Ollama)',22,10,'Large',NULL,NULL,NULL,NULL,'~20-30M',131072,1,0,NULL,0,0.12,0.37,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (95,'nvidia','meta/llama-3.3-70b-instruct','Llama 3.3 70B (NV)',17,6,'Medium',40,NULL,NULL,NULL,'~3M (credits)',131072,1,0,NULL,1,0.1,0.32,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (96,'nvidia','meta/llama-4-maverick-17b-128e-instruct','Llama 4 Maverick (NV)',11,6,'Medium',40,NULL,NULL,NULL,'~3M (credits)',131072,1,1,NULL,1,0.15,0.6,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (97,'nvidia','deepseek-ai/deepseek-v4-pro','DeepSeek V4 Pro (NV)',3,9,'Frontier',40,NULL,NULL,NULL,'~2M (credits)',131072,1,0,NULL,1,0.435,0.87,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (98,'nvidia','mistralai/mistral-large-3-675b-instruct-2512','Mistral Large 3 675B (NV)',3,9,'Medium',40,NULL,NULL,NULL,'~2M (credits)',131072,1,0,NULL,1,0.5,1.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (99,'nvidia','minimaxai/minimax-m2.7','MiniMax M2.7 (NV)',3,9,'Frontier',40,NULL,NULL,NULL,'~2M (credits)',196608,1,0,NULL,1,0.279,1.2,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (100,'nvidia','nvidia/nemotron-3-super-120b-a12b','Nemotron 3 Super 120B (NV)',22,9,'Large',40,NULL,NULL,NULL,'~2M (credits)',262144,1,0,NULL,1,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (101,'nvidia','nvidia/nemotron-3-nano-30b-a3b','Nemotron 3 Nano 30B (NV)',22,9,'Medium',40,NULL,NULL,NULL,'~3M (credits)',262144,1,0,NULL,0,0.05,0.2,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (102,'nvidia','google/gemma-4-31b-it','Gemma 4 31B (NV)',19,9,'Large',40,NULL,NULL,NULL,'~3M (credits)',262144,0,0,NULL,0,0.12,0.37,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (103,'nvidia','moonshotai/kimi-k2.6','Kimi K2.6 (NV)',3,9,'Frontier',40,NULL,NULL,NULL,'~2M (credits)',131072,1,0,NULL,1,0.684,3.42,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (104,'cerebras','gpt-oss-120b','GPT-OSS 120B (Cerebras)',6,1,'Large',5,2400,30000,1000000,'~30M',131072,1,0,NULL,1,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (105,'cerebras','llama3.1-8b','Llama 3.1 8B (Cerebras)',28,1,'Small',5,2400,30000,1000000,'~30M',131072,0,0,NULL,0,0.02,0.03,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (106,'groq','groq/compound','Compound (Groq)',6,2,'Large',30,250,70000,NULL,'~6M',131072,1,0,NULL,0,0.039,0.18,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (107,'groq','groq/compound-mini','Compound Mini (Groq)',18,2,'Medium',30,250,70000,NULL,'~6M',131072,1,0,NULL,0,0.029,0.14,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (108,'kilo','nvidia/nemotron-3-super-120b-a12b:free','Nemotron 3 Super 120B (Kilo)',22,9,'Large',NULL,NULL,NULL,NULL,'~2-3M (200/hr)',262144,1,0,NULL,1,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (109,'pollinations','openai-fast','GPT-OSS 20B (Pollinations)',18,10,'Medium',NULL,NULL,NULL,NULL,'~? (anon)',131072,1,0,NULL,0,0.029,0.14,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (112,'llm7','codestral-latest','Codestral (LLM7)',16,8,'Small',100,NULL,NULL,NULL,'~2-3M (100/hr)',32000,1,0,NULL,1,0.3,0.9,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (117,'openrouter','openrouter/owl-alpha','Owl Alpha (OR-house)',5,9,'Frontier',20,200,NULL,NULL,'~6M',1048576,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (118,'openrouter','nousresearch/hermes-3-llama-3.1-405b:free','Hermes 3 405B (free)',17,9,'Large',20,200,NULL,NULL,'~6M',131072,1,0,NULL,0,1.0,1.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (119,'groq','openai/gpt-oss-safeguard-20b','GPT-OSS Safeguard 20B (Groq)',18,2,'Medium',30,1000,8000,200000,'~6M',131072,1,0,NULL,1,0.075,0.3,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (120,'cloudflare','@cf/nvidia/nemotron-3-120b-a12b','Nemotron 3 120B (CF)',9,11,'Large',NULL,NULL,NULL,NULL,'~5-10M',262144,1,0,NULL,0,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (121,'cloudflare','@cf/google/gemma-4-26b-a4b-it','Gemma 4 26B-A4B it (CF)',22,11,'Large',NULL,NULL,NULL,NULL,'~10-20M',262144,1,0,NULL,0,0.06,0.33,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (122,'google','gemini-3.5-flash','Gemini 3.5 Flash',3,5,'Frontier',10,20,250000,NULL,'~3M',1048576,1,1,NULL,1,1.5,9.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (123,'nvidia','deepseek-ai/deepseek-v4-flash','DeepSeek V4 Flash (NV)',4,9,'Frontier',40,NULL,NULL,NULL,'~3M (credits)',131072,1,0,NULL,1,0.098,0.197,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (124,'nvidia','z-ai/glm-5.1','GLM-5.1 (NV, slow cold-start)',5,9,'Frontier',40,NULL,NULL,NULL,'~3M (credits)',200000,1,0,NULL,1,0.98,3.08,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (125,'nvidia','qwen/qwen3-coder-480b-a35b-instruct','Qwen3-Coder 480B (NV)',2,9,'Medium',40,NULL,NULL,NULL,'~3M (credits)',262144,1,0,NULL,1,0.22,1.8,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (126,'mistral','mistral-small-latest','Mistral Small 4',14,8,'Medium',2,NULL,500000,NULL,'~50-100M',262144,1,0,NULL,1,0.15,0.6,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (127,'mistral','ministral-8b-latest','Ministral 3 8B',28,8,'Small',2,NULL,500000,NULL,'~50-100M',262144,1,0,NULL,1,0.15,0.15,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (128,'cohere','command-a-reasoning-08-2025','Command A Reasoning (08-2025)',13,11,'Large',20,33,NULL,NULL,'~1-2M',256000,1,0,NULL,1,2.5,10.0,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (129,'cohere','command-r-08-2024','Command R (08-2024)',25,11,'Small',20,33,NULL,NULL,'~1-2M',131072,1,0,NULL,1,0.15,0.6,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (130,'ollama','qwen3-coder-next','Qwen3-Coder Next (Ollama)',3,9,'Large',NULL,NULL,NULL,NULL,'~10-20M',262144,1,0,NULL,1,0.11,0.8,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (131,'huggingface','deepseek-ai/DeepSeek-V4-Flash','DeepSeek V4 Flash (HF)',4,9,'Frontier',NULL,NULL,NULL,NULL,'~1-3M',131072,1,0,NULL,1,0.098,0.197,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (132,'huggingface','moonshotai/Kimi-K2.6','Kimi K2.6 (HF)',3,9,'Frontier',NULL,NULL,NULL,NULL,'~1-3M',262144,1,0,NULL,1,0.684,3.42,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (133,'huggingface','Qwen/Qwen3-Coder-Next','Qwen3-Coder Next (HF)',3,9,'Large',NULL,NULL,NULL,NULL,'~1-3M',262144,1,0,NULL,1,0.11,0.8,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (134,'opencode','big-pickle','Big Pickle (OpenCode Zen, stealth)',10,4,'Large',20,200,NULL,NULL,'promo (trial)',131072,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (135,'opencode','deepseek-v4-flash-free','DeepSeek V4 Flash Free (OpenCode Zen)',4,4,'Frontier',20,200,NULL,NULL,'promo (trial)',131072,1,0,NULL,1,0.098,0.197,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (136,'opencode','mimo-v2.5-free','MiMo-V2.5 Free (OpenCode Zen)',14,4,'Medium',20,200,NULL,NULL,'promo (trial)',131072,1,0,NULL,0,0.14,0.28,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (137,'opencode','nemotron-3-super-free','Nemotron 3 Super Free (OpenCode Zen)',12,4,'Large',20,200,NULL,NULL,'promo (trial)',131072,0,0,NULL,1,0.09,0.45,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (138,'google','gemma-4-31b-it','Gemma 4 31B IT',19,4,'Large',15,1000,250000,NULL,'~30M',32768,1,0,NULL,0,0.12,0.37,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (139,'google','gemma-4-26b-a4b-it','Gemma 4 26B IT',20,4,'Large',15,1000,250000,NULL,'~30M',32768,1,0,NULL,0,0.06,0.33,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (140,'kilo','poolside/laguna-m.1:free','Poolside Laguna M.1 (Kilo)',13,8,'Large',NULL,NULL,NULL,NULL,'free · 200/hr per IP',262144,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (141,'kilo','poolside/laguna-xs.2:free','Poolside Laguna XS.2 (Kilo)',16,4,'Medium',NULL,NULL,NULL,NULL,'free · 200/hr per IP',262144,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (143,'kilo','stepfun/step-3.7-flash:free','StepFun Step 3.7 Flash (Kilo)',14,3,'Medium',NULL,NULL,NULL,NULL,'free · 200/hr per IP',262144,1,0,NULL,0,0.2,1.15,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (144,'openrouter','moonshotai/kimi-k2.6:free','Kimi K2.6 (OR free)',3,9,'Frontier',20,200,NULL,NULL,'~6M',262144,1,0,NULL,1,0.684,3.42,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (145,'openrouter','nvidia/nemotron-3-ultra-550b-a55b:free','Nemotron 3 Ultra 550B (free, slow)',7,11,'Frontier',20,200,NULL,NULL,'~6M',1000000,0,0,NULL,1,0.5,2.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (146,'openrouter','nvidia/nemotron-nano-12b-v2-vl:free','Nemotron Nano 12B VL (free)',26,9,'Medium',20,200,NULL,NULL,'~6M',128000,1,1,NULL,1,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (147,'openrouter','meta-llama/llama-3.2-3b-instruct:free','Llama 3.2 3B (free)',30,9,'Small',20,200,NULL,NULL,'~6M',131072,1,0,NULL,0,0.05,0.34,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (148,'openrouter','cognitivecomputations/dolphin-mistral-24b-venice-edition:free','Dolphin Mistral 24B Venice (free)',25,9,'Medium',20,200,NULL,NULL,'~6M',32768,1,0,NULL,0,NULL,NULL,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (149,'zhipu','glm-4.6v-flash','GLM-4.6V Flash',21,4,'Large',NULL,NULL,NULL,NULL,'~30M',131072,1,1,NULL,1,0.3,0.9,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (150,'opencode','nemotron-3-ultra-free','Nemotron 3 Ultra Free (OpenCode Zen)',7,4,'Frontier',20,200,NULL,NULL,'promo (trial)',131072,1,0,NULL,1,0.5,2.5,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO models (id,platform,model_id,display_name,intelligence_rank,speed_rank,size_label,rpm_limit,rpd_limit,tpm_limit,tpd_limit,monthly_token_budget,context_window,enabled,supports_vision,key_id,supports_tools,paid_input_per_m,paid_output_per_m,source,endpoint_scope) VALUES (151,'opencode','minimax-m3-free','MiniMax M3 Free (OpenCode Zen)',4,4,'Frontier',20,200,NULL,NULL,'promo (trial)',131072,0,0,NULL,1,0.3,1.2,'catalog','') ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (1,'gemini-embedding-001','google','gemini-embedding-001','Gemini Embedding',3072,2048,1,1,'100 rpm · 1K req/day',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (2,'llama-nemotron-embed-vl-1b-v2','nvidia','nvidia/llama-nemotron-embed-vl-1b-v2','Nemotron Embed VL 1B',2048,8192,1,1,'~40 rpm',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (3,'llama-nemotron-embed-vl-1b-v2','openrouter','nvidia/llama-nemotron-embed-vl-1b-v2','Nemotron Embed VL 1B (OR)',2048,8192,2,1,'$0/M tok',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (4,'llama-nemotron-embed-1b-v2','nvidia','nvidia/llama-nemotron-embed-1b-v2','Nemotron Embed 1B',2048,8192,1,1,'~40 rpm',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (5,'nv-embedqa-e5-v5','nvidia','nvidia/nv-embedqa-e5-v5','NV-EmbedQA E5 v5',1024,512,1,1,'~40 rpm',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (8,'bge-m3','cloudflare','@cf/baai/bge-m3','BGE-M3',1024,8192,1,1,'10K neurons/day (shared)',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (9,'bge-m3','huggingface','BAAI/bge-m3','BGE-M3 (HF)',1024,8192,2,1,'$0.10/mo credits',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (10,'embeddinggemma-300m','cloudflare','@cf/google/embeddinggemma-300m','EmbeddingGemma 300M',768,2048,1,1,'10K neurons/day (shared)',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (11,'qwen3-embedding-0.6b','cloudflare','@cf/qwen/qwen3-embedding-0.6b','Qwen3 Embedding 0.6B',1024,4096,1,1,'10K neurons/day (shared)',NULL) ON CONFLICT DO NOTHING;
INSERT INTO embedding_models (id,family,platform,model_id,display_name,dimensions,max_input_tokens,priority,enabled,quota_label,key_id) VALUES (12,'embed-v4.0','cohere','embed-v4.0','Cohere Embed v4',1536,128000,1,0,'1K calls/mo (shared w/ chat)',NULL) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (1,1,1,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (6,6,6,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (8,10,8,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (10,2,10,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (11,7,11,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (12,15,12,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (14,23,14,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (17,16,17,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (18,14,18,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (19,3,19,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (20,17,20,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (21,18,21,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (22,19,22,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (23,20,23,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (24,21,24,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (26,38,26,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (27,39,27,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (32,45,31,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (34,52,33,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (35,60,34,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (37,61,36,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (39,62,38,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (41,57,40,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (42,56,41,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (43,47,42,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (44,46,43,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (45,53,44,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (46,54,45,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (48,44,47,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (49,59,48,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (50,55,49,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (51,63,50,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (52,69,51,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (54,65,53,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (55,66,54,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (56,68,55,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (57,67,56,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (58,70,57,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (59,71,58,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (62,74,61,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (63,80,62,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (64,75,63,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (65,76,64,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (66,77,65,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (67,78,66,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (68,79,67,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (69,83,68,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (72,84,71,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (73,85,72,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (74,86,73,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (75,87,74,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (76,88,75,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (77,89,76,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (78,90,77,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (79,91,78,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (80,92,79,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (81,93,80,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (82,94,81,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (83,97,82,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (84,98,83,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (85,99,84,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (86,103,85,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (87,104,86,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (88,106,87,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (89,96,88,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (91,112,90,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (92,95,91,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (93,107,92,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (94,109,93,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (96,102,95,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (97,100,96,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (98,101,97,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (99,108,98,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (100,105,99,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (104,117,103,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (106,118,105,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (107,125,106,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (108,122,107,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (109,130,108,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (110,132,109,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (111,133,110,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (112,123,111,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (113,131,112,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (114,124,113,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (115,120,114,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (116,128,115,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (117,126,116,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (118,119,117,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (119,121,118,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (120,129,119,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (121,127,120,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (122,135,121,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (123,134,122,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (124,137,123,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (125,136,124,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (126,138,125,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (127,139,126,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (128,140,127,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (129,143,128,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (130,141,129,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (131,144,130,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (132,145,131,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (133,149,132,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (134,148,133,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (135,146,134,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (136,147,135,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (137,151,136,1) ON CONFLICT DO NOTHING;
INSERT INTO fallback_config (id,model_db_id,priority,enabled) VALUES (138,150,137,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (1,1,1,1,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (3,1,6,6,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (4,1,10,8,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (5,1,2,10,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (6,1,7,11,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (7,1,15,12,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (8,1,23,14,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (9,1,16,17,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (10,1,14,18,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (11,1,3,19,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (12,1,17,20,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (13,1,18,21,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (14,1,19,22,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (15,1,20,23,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (16,1,21,24,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (17,1,38,26,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (18,1,39,27,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (19,1,45,31,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (20,1,52,33,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (21,1,60,34,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (22,1,61,36,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (23,1,62,38,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (24,1,57,40,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (25,1,56,41,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (26,1,47,42,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (27,1,46,43,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (28,1,53,44,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (29,1,54,45,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (31,1,44,47,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (32,1,59,48,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (33,1,55,49,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (34,1,63,50,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (35,1,69,51,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (36,1,65,53,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (37,1,66,54,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (38,1,68,55,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (39,1,67,56,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (40,1,70,57,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (41,1,71,58,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (42,1,74,61,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (43,1,80,62,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (44,1,75,63,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (45,1,76,64,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (46,1,77,65,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (47,1,78,66,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (48,1,79,67,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (49,1,83,68,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (50,1,84,71,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (51,1,85,72,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (52,1,86,73,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (53,1,87,74,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (54,1,88,75,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (55,1,89,76,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (56,1,90,77,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (57,1,91,78,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (58,1,92,79,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (59,1,93,80,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (60,1,94,81,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (61,1,97,82,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (62,1,98,83,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (63,1,99,84,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (64,1,103,85,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (65,1,104,86,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (66,1,106,87,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (67,1,96,88,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (68,1,112,90,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (69,1,95,91,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (70,1,107,92,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (71,1,109,93,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (72,1,102,95,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (73,1,100,96,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (74,1,101,97,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (75,1,108,98,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (76,1,105,99,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (77,1,117,103,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (78,1,118,105,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (79,1,125,106,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (80,1,122,107,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (81,1,130,108,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (82,1,132,109,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (83,1,133,110,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (84,1,123,111,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (85,1,131,112,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (86,1,124,113,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (87,1,120,114,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (88,1,128,115,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (89,1,126,116,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (90,1,119,117,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (91,1,121,118,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (92,1,129,119,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (93,1,127,120,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (94,1,135,121,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (95,1,134,122,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (96,1,137,123,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (97,1,136,124,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (98,1,138,125,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (99,1,139,126,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (100,1,140,127,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (101,1,143,128,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (102,1,141,129,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (103,1,144,130,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (104,1,145,131,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (105,1,149,132,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (106,1,148,133,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (107,1,146,134,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (108,1,147,135,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (109,1,151,136,1) ON CONFLICT DO NOTHING;
INSERT INTO profile_models (id,profile_id,model_db_id,priority,enabled) VALUES (110,1,150,137,1) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (1,'keyless-anonymous','No API key required','Routes anonymously — the catalog ships a keyless sentinel row and calls work with no account or key.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (2,'ovh-anon-trickle','Anonymous tier is 2 req/min','OVH AI Endpoints anonymous mode is documented at 2 req/min per IP per model (observed even stricter across models). The 400 req/min authenticated tier requires a Public Cloud project with a payment method, so the catalog ships the keyless path. Treat as a breadth/fallback tier, not a throughput tier.','warning',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (3,'pollinations-degraded','Publishable key uses recurring shared capacity','Pollinations chat uses https://gen.pollinations.ai/v1 with a free publishable API key. Shared free capacity currently accrues at one pollen per IP per hour; the legacy text host is no longer used.','warning',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (4,'or-free-cap-account-wide','Daily :free cap is account-wide','OpenRouter’s :free daily cap (50/day, or 1000/day once you have ever bought $10 of credits) is shared across ALL :free models on the account, not per model. Per-row rpd values here are therefore optimistic; the router’s cooldown handling absorbs the shared 429s.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (5,'zen-promo-roster','Limited-time promo, roster rotates','OpenCode Zen free models are explicitly limited-time promotional access ("available for a limited time" per the docs), not a recurring quota. The roster rotates: qwen3.6-plus and minimax-m3 promos already ended. Expect any row here to die without notice; prompts/outputs may be used for model improvement.','warning',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (6,'cloudflare-key-format','Key is account_id:token','Cloudflare Workers AI authenticates with a combined credential in the form "account_id:token", not a bare token.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (7,'nvidia-rate-limited','Recurring free, 40 RPM, eval-only ToS','NVIDIA NIM replaced its depleting trial credits with a recurring per-account rate limit (40 RPM default, varies by model), verified June 2026. The trial ToS still scopes usage to evaluation/prototyping, not production.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (8,'nim-gemma-hung','NIM gemma route hangs','The NVIDIA NIM gemma endpoint is listed but hangs (capacity starvation plus an upstream FlashAttention bug). Paused; probe with a 120s timeout before re-enabling.','blocker',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (9,'or-ultra-hangs','OpenRouter ultra route hangs','nemotron-3-ultra (550B) on OpenRouter takes 180s+ even on trivial prompts (heavily congested), so its OR row is seeded disabled. Use the OpenCode Zen route instead.','warning',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (10,'zen-serves-ultra-fast','Zen serves the 550B fast','OpenCode Zen serves nemotron-3-ultra in ~2s with working tool calls where the OpenRouter route hangs — the live-verified path for this model.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirks (id,slug,title,body,severity,created_at_ms,updated_at_ms) VALUES (11,'zhipu-shared-key','Works with existing Zhipu key','glm-4.6v-flash is listed Free on Z.AI and answers 200 with the existing bigmodel.cn key; vision and structured tool calls both live-verified.','info',1794726959297,1794726959297) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (1,1,'kilo',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (2,1,'llm7',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (3,1,'ovh',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (4,2,'ovh',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (5,3,'pollinations',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (6,4,'openrouter','*:free') ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (7,5,'opencode',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (8,6,'cloudflare',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (9,7,'nvidia',NULL) ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (10,8,'nvidia','*gemma*') ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (11,9,'openrouter','*nemotron-3-ultra*') ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (12,10,'opencode','*nemotron-3-ultra*') ON CONFLICT DO NOTHING;
INSERT INTO quirk_targets (id,quirk_id,platform,model_glob) VALUES (13,11,'zhipu','*glm-4.6v*') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('embeddings_default_family','gemini-embedding-001') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('active_profile_id','1') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('total_requests','0') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('total_input_tokens','0') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('total_output_tokens','0') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('ollama_emulation','off') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('expose_cc_discovery_aliases','0') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('enable_mcp','0') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('migration_llmtr_reenabled_key_ids','[]') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('migration_github_removed_rows','{"api_keys":[],"models":[{"id":12,"platform":"github","model_id":"gpt-4o","display_name":"GPT-4o","intelligence_rank":25,"speed_rank":7,"size_label":"Medium","rpm_limit":10,"rpd_limit":50,"tpm_limit":null,"tpd_limit":null,"monthly_token_budget":"~18M","context_window":8000,"enabled":1,"supports_vision":1,"key_id":null,"supports_tools":1,"paid_input_per_m":null,"paid_output_per_m":null,"source":"catalog","endpoint_scope":""},{"id":58,"platform":"github","model_id":"openai/gpt-4.1","display_name":"GPT-4.1 (GitHub)","intelligence_rank":20,"speed_rank":7,"size_label":"Large","rpm_limit":10,"rpd_limit":50,"tpm_limit":null,"tpd_limit":null,"monthly_token_budget":"~9M","context_window":8000,"enabled":1,"supports_vision":1,"key_id":null,"supports_tools":1,"paid_input_per_m":null,"paid_output_per_m":null,"source":"catalog","endpoint_scope":""}],"embedding_models":[{"id":7,"family":"text-embedding-3-large","platform":"github","model_id":"openai/text-embedding-3-large","display_name":"Text Embedding 3 Large","dimensions":3072,"max_input_tokens":8191,"priority":1,"enabled":1,"quota_label":"rate-limited free","key_id":null},{"id":6,"family":"text-embedding-3-small","platform":"github","model_id":"openai/text-embedding-3-small","display_name":"Text Embedding 3 Small","dimensions":1536,"max_input_tokens":8191,"priority":1,"enabled":1,"quota_label":"rate-limited free","key_id":null}],"media_models":[],"model_overrides":[],"fallback_config":[{"id":2,"model_db_id":12,"priority":2,"enabled":1},{"id":47,"model_db_id":58,"priority":46,"enabled":1}],"profile_models":[{"id":2,"profile_id":1,"model_db_id":12,"priority":2,"enabled":1},{"id":30,"profile_id":1,"model_db_id":58,"priority":46,"enabled":1}]}') ON CONFLICT DO NOTHING;
INSERT INTO settings (key,value) VALUES ('migration_auray_removed_rows','{"api_keys":[],"models":[],"embedding_models":[],"media_models":[],"model_overrides":[],"fallback_config":[],"profile_models":[]}') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (1,'20260101_000000_legacy_baseline.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (2,'20260627_000001_custom_provider_modalities.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (3,'20260627_000002_catalog_model_state.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (4,'20260628_120000_request_aggregates.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (5,'20260630_000001_github_gpt41_context.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (6,'20260706_000001_request_client_info.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (7,'20260706_000002_custom_model_tool_support.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (8,'20260714_000001_profile_chain_backfill.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (9,'20260720_000001_key_health_error.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (10,'20260726_000001_cooldown_probe_provenance.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (11,'20260726_000002_request_attempts.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (12,'20260726_000003_model_source_provenance.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (13,'20260726_000004_media_model_meta.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (14,'20260726_000005_request_served_model.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (15,'20260726_000006_attempt_error_summary.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (16,'20260727_000001_agent_compatibility.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (17,'20260728_000001_tombstone_provenance.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (18,'20260729_000001_custom_model_endpoint_identity.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (19,'20260802_000001_custom_endpoint_host_labels.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (20,'20260805_000001_key_model_scope.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (21,'20260805_000002_client_profiles.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (22,'20260810_000001_api_key_proxy.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (23,'20260819_000001_custom_model_tombstones.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (24,'20260820_000001_playground_conversations.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (25,'20260823_000001_server_logs.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (26,'20260823_000002_backups_table.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (27,'20260823_000003_attempt_key_label.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (28,'20260823_000004_profile_auto_include.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (29,'20260901_000001_idempotency_claims.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (30,'20260901_000002_quota_observation_lookup.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (31,'20260901_000003_request_caller.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (32,'20260902_000001_analytics_latency_percentile_index.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (33,'20260903_000001_mcp_enabled_default.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (34,'20260903_000002_response_cache.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (35,'20260904_000001_key_monthly_budget.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (36,'20260913_000001_request_model_attribution.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (37,'20260914_000001_key_monthly_usage.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (38,'20260915_000001_quota_snapshot_freshness.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (39,'20260930_000001_custom_endpoint_group_label.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (40,'20261007_000001_model_probe_status.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (41,'20261013_000001_search_engines.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (42,'20261016_000001_decision_requests.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (43,'20261017_000001_llmtr_reenable_keys.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (44,'20261017_000002_remove_github_provider.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (45,'20261017_233153_request_failure_attribution.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (46,'20261019_000001_remove_auray_provider.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (47,'20261020_000001_key_last_healthy_at.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (48,'20261028_000001_custom_media_endpoint_identity.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (49,'20261104_000001_cloudflare_neuron_usage.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (50,'20261111_000001_model_monthly_usage.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;
INSERT INTO migrations (id,filename,applied_at) VALUES (51,'20261111_000002_profile_routing_strategy.ts','2026-11-15 07:15:59') ON CONFLICT DO NOTHING;

-- Fix serial sequences after explicit-id seeding
SELECT setval(pg_get_serial_sequence('api_keys','id'), COALESCE((SELECT MAX(id) FROM api_keys),0)+1, false);
SELECT setval(pg_get_serial_sequence('backups','id'), COALESCE((SELECT MAX(id) FROM backups),0)+1, false);
SELECT setval(pg_get_serial_sequence('client_profiles','id'), COALESCE((SELECT MAX(id) FROM client_profiles),0)+1, false);
SELECT setval(pg_get_serial_sequence('decision_requests','id'), COALESCE((SELECT MAX(id) FROM decision_requests),0)+1, false);
SELECT setval(pg_get_serial_sequence('embedding_models','id'), COALESCE((SELECT MAX(id) FROM embedding_models),0)+1, false);
SELECT setval(pg_get_serial_sequence('fallback_config','id'), COALESCE((SELECT MAX(id) FROM fallback_config),0)+1, false);
SELECT setval(pg_get_serial_sequence('idempotency_claims','id'), COALESCE((SELECT MAX(id) FROM idempotency_claims),0)+1, false);
SELECT setval(pg_get_serial_sequence('media_models','id'), COALESCE((SELECT MAX(id) FROM media_models),0)+1, false);
SELECT setval(pg_get_serial_sequence('migrations','id'), COALESCE((SELECT MAX(id) FROM migrations),0)+1, false);
SELECT setval(pg_get_serial_sequence('models','id'), COALESCE((SELECT MAX(id) FROM models),0)+1, false);
SELECT setval(pg_get_serial_sequence('playground_conversations','id'), COALESCE((SELECT MAX(id) FROM playground_conversations),0)+1, false);
SELECT setval(pg_get_serial_sequence('profile_models','id'), COALESCE((SELECT MAX(id) FROM profile_models),0)+1, false);
SELECT setval(pg_get_serial_sequence('profiles','id'), COALESCE((SELECT MAX(id) FROM profiles),0)+1, false);
SELECT setval(pg_get_serial_sequence('quirk_targets','id'), COALESCE((SELECT MAX(id) FROM quirk_targets),0)+1, false);
SELECT setval(pg_get_serial_sequence('quirks','id'), COALESCE((SELECT MAX(id) FROM quirks),0)+1, false);
SELECT setval(pg_get_serial_sequence('rate_limit_usage','id'), COALESCE((SELECT MAX(id) FROM rate_limit_usage),0)+1, false);
SELECT setval(pg_get_serial_sequence('request_attempts','id'), COALESCE((SELECT MAX(id) FROM request_attempts),0)+1, false);
SELECT setval(pg_get_serial_sequence('requests','id'), COALESCE((SELECT MAX(id) FROM requests),0)+1, false);
SELECT setval(pg_get_serial_sequence('search_requests','id'), COALESCE((SELECT MAX(id) FROM search_requests),0)+1, false);
SELECT setval(pg_get_serial_sequence('url_tokens','id'), COALESCE((SELECT MAX(id) FROM url_tokens),0)+1, false);
SELECT setval(pg_get_serial_sequence('users','id'), COALESCE((SELECT MAX(id) FROM users),0)+1, false);
