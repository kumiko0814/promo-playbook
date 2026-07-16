-- ============================================================
-- Merone プロモーション進行ToDo  テーブル定義
-- Supabase ダッシュボード → SQL Editor に丸ごと貼って RUN するだけ
-- （Re:alize と同じプロジェクトに相乗り。既存テーブルには一切触れません）
-- ============================================================
-- ★社内の作業チェックリスト。機密の顧客データは持ちません。
--   誰でも（ログイン不要で）開いて分担できるよう anon 許可にしています。
--   進捗はプロモ単位（run_id）で分かれます。URLの ?promo=xxx で切替。
-- ============================================================

-- 1) タスクの状態（1タスク＝1行）
CREATE TABLE IF NOT EXISTS promo_tasks (
  run_id        TEXT NOT NULL DEFAULT 'default',  -- どのプロモか（?promo=xxx）
  task_key      TEXT NOT NULL,                     -- タスクの固定ID（サイト側定義）
  done          BOOLEAN DEFAULT FALSE,             -- 完了チェック
  owner_depts   TEXT,                              -- 担当部署（複数可・カンマ区切り。NULL=初期値のまま）
  owner_members TEXT,                              -- 担当メンバー（メールをカンマ区切り）
  memo          TEXT DEFAULT '',                   -- メモ・進捗コメント
  link_url      TEXT DEFAULT '',                   -- このプロモ用リンク（オプチャ/YouTube等）
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (run_id, task_key)
);
-- 既存テーブルへの移行（新チーム分け・複数担当対応。前バージョンから使ってる場合）
ALTER TABLE promo_tasks ADD COLUMN IF NOT EXISTS owner_depts   TEXT;
ALTER TABLE promo_tasks ADD COLUMN IF NOT EXISTS owner_members TEXT;

-- 2) メンバー（メールを目印に、自分で表示名と所属を設定）
CREATE TABLE IF NOT EXISTS promo_members (
  email       TEXT PRIMARY KEY,   -- 目印
  name        TEXT DEFAULT '',    -- 表示名（自分で設定）
  depts       TEXT DEFAULT '',    -- 所属チーム（複数可・カンマ区切り）
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- リアルタイム同期（全員の画面に即反映）
ALTER TABLE promo_tasks   REPLICA IDENTITY FULL;
ALTER TABLE promo_members REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='promo_tasks') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE promo_tasks;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='promo_members') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE promo_members;
  END IF;
END $$;

-- RLS: ログイン不要（anon）で読み書き
ALTER TABLE promo_tasks   ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "promo_anon_select" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_insert" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_update" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_delete" ON promo_tasks;
DROP POLICY IF EXISTS "promo_tasks_anon_all"   ON promo_tasks;
DROP POLICY IF EXISTS "promo_members_anon_all" ON promo_members;
CREATE POLICY "promo_tasks_anon_all"   ON promo_tasks   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "promo_members_anon_all" ON promo_members FOR ALL USING (true) WITH CHECK (true);

-- 「Success. No rows returned」でOK。
