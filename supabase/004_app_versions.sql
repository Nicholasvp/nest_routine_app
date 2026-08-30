-- Tabela de controle de versão do app
CREATE TABLE app_versions (
  id SERIAL PRIMARY KEY,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'all')),
  latest_version TEXT NOT NULL,
  min_version TEXT NOT NULL,
  release_notes TEXT,
  store_url TEXT,
  is_force_update BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Habilitar RLS
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Qualquer usuário autenticado pode ler versões
CREATE POLICY "Authenticated users can view versions"
  ON app_versions FOR SELECT
  TO authenticated
  USING (true);

-- Índices
CREATE INDEX idx_app_versions_platform ON app_versions(platform);
CREATE INDEX idx_app_versions_created_at ON app_versions(created_at DESC);

-- Dados de exemplo (remover em produção)
INSERT INTO app_versions (platform, latest_version, min_version, release_notes, store_url, is_force_update)
VALUES
  ('all', '1.4.0', '1.3.0', '• Previsões mais precisas\n• Correções de bugs\n• Melhorias de performance', 'https://apps.apple.com/app/nestroutine/id6478912345', false);
