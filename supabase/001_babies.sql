-- Tabela de bebês
CREATE TABLE babies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  photo_path TEXT,
  date_of_birth TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Habilitar RLS
ALTER TABLE babies ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Users can view own babies"
  ON babies FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own babies"
  ON babies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own babies"
  ON babies FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own babies"
  ON babies FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Índices
CREATE INDEX idx_babies_user_id ON babies(user_id);
