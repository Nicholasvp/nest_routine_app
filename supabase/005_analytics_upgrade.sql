-- Upgrade da tabela de analytics para funil de paywall e onboarding
-- Resolve: inserts de usuarios anonimos bloqueados por RLS, ausencia de
-- session_id (costura onboarding -> paywall) e ausencia de duration_ms.

-- Novas colunas
ALTER TABLE analytics_events
  ADD COLUMN IF NOT EXISTS session_id TEXT;

ALTER TABLE analytics_events
  ADD COLUMN IF NOT EXISTS duration_ms INTEGER;

-- Indices para as novas colunas
CREATE INDEX IF NOT EXISTS idx_analytics_session_id
  ON analytics_events(session_id);

CREATE INDEX IF NOT EXISTS idx_analytics_event_name_created_at
  ON analytics_events(event_name, created_at DESC);

-- Politicas de escrita para usuarios anonimos (sem login).
-- O onboarding e a primeira impressao de paywall acontecem antes da conta
-- existir, entao sem isso o topo do funil fica cego.
-- Gravacao permitida apenas com user_id NULL para o role anon.
DROP POLICY IF EXISTS "Anonymous users can insert analytics" ON analytics_events;

CREATE POLICY "Anonymous users can insert analytics"
  ON analytics_events FOR INSERT
  TO anon
  WITH CHECK (user_id IS NULL);

-- Leitura: analistas/admins leem tudo; usuario autenticado le apenas o seu.
DROP POLICY IF EXISTS "Users can view own analytics" ON analytics_events;

CREATE POLICY "Users can view own analytics"
  ON analytics_events FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Politica de insert para logados ja existe em 003_analytics.sql e
-- continua valendo (auth.uid() = user_id).

-- View de funil do paywall: uma linha por sessao onde houve paywall_shown.
DROP VIEW IF EXISTS vw_paywall_funnel;

CREATE VIEW vw_paywall_funnel AS
SELECT
  s.session_id,
  s.user_id,
  s.platform,
  s.app_version,
  s.created_at            AS shown_at,
  s.properties->>'trigger' AS trigger,
  (s.properties->>'dismiss_count')::int AS dismiss_count_before,
  COALESCE(r.duration_ms, 0)            AS duration_ms
FROM analytics_events s
LEFT JOIN LATERAL (
  SELECT a.duration_ms
  FROM analytics_events a
  WHERE a.session_id = s.session_id
    AND a.event_name IN ('paywall_dismissed', 'paywall_purchased', 'paywall_restored')
    AND a.created_at >= s.created_at
  ORDER BY a.created_at
  LIMIT 1
) r ON true
WHERE s.event_name = 'paywall_shown';

-- View de funil do onboarding: uma linha por sessao que iniciou o onboarding.
DROP VIEW IF EXISTS vw_onboarding_funnel;

CREATE VIEW vw_onboarding_funnel AS
SELECT
  session_id,
  MIN(created_at) FILTER (WHERE event_name = 'onboarding_started')   AS started_at,
  MAX(created_at) FILTER (WHERE event_name = 'onboarding_completed') AS completed_at,
  MAX(created_at) FILTER (WHERE event_name = 'onboarding_skipped')   AS skipped_at,
  COUNT(*) FILTER (WHERE event_name = 'onboarding_page_view')        AS pages_viewed,
  COALESCE(
    SUM(duration_ms) FILTER (WHERE event_name = 'onboarding_page_view'), 0
  )                                                                  AS total_page_ms
FROM analytics_events
WHERE event_name IN (
  'onboarding_started',
  'onboarding_page_view',
  'onboarding_skipped',
  'onboarding_completed'
)
GROUP BY session_id;
