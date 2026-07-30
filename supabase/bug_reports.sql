-- Tabela para reports de bugs dos usuários
CREATE TABLE bug_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  email TEXT,
  app_version TEXT,
  platform TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE bug_reports ENABLE ROW LEVEL SECURITY;

-- Política: qualquer pessoa logada pode inserir
CREATE POLICY "Authenticated users can insert bug reports"
  ON bug_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Política: apenas o próprio usuário pode ver seus reports (ou admin via service_role)
CREATE POLICY "Users can view own bug reports"
  ON bug_reports
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Índices para performance
CREATE INDEX idx_bug_reports_user_id ON bug_reports(user_id);
CREATE INDEX idx_bug_reports_created_at ON bug_reports(created_at DESC);
