-- ============================================================
-- Merone プロモーション進行ToDo  テーブル定義
-- Supabase ダッシュボード → SQL Editor に丸ごと貼って RUN するだけ
-- （Re:alize と同じプロジェクトに相乗り。既存テーブルには一切触れません）
-- ============================================================
-- ★このToDoは「社内の作業チェックリスト」で、機密の顧客データは持ちません。
--   なので誰でも（ログイン不要で）開いて分担できるように anon 許可にしています。
--   進捗はプロモ単位（run_id）で分かれます。URLの ?promo=xxx で切替。
-- ============================================================

-- タスクの状態（1タスク＝1行。定義はサイト側に固定、ここは可変分だけ保存）
CREATE TABLE IF NOT EXISTS promo_tasks (
  run_id      TEXT NOT NULL DEFAULT 'default',   -- どのプロモか（?promo=xxx）
  task_key    TEXT NOT NULL,                      -- タスクの固定ID（サイト側定義）
  done        BOOLEAN DEFAULT FALSE,              -- 完了チェック
  owner_name  TEXT DEFAULT '',                    -- 実際にやる人（自分の名前を書く）
  memo        TEXT DEFAULT '',                    -- メモ・進捗コメント
  link_url    TEXT DEFAULT '',                    -- このプロモ用のリンク（オプチャ/YouTube等）
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (run_id, task_key)
);

-- リアルタイム同期を有効化（全員の画面に即反映）
ALTER TABLE promo_tasks REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'promo_tasks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE promo_tasks;
  END IF;
END $$;

-- RLS: ログイン不要（anon）で読み書きできる社内チェックリスト
ALTER TABLE promo_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "promo_anon_select" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_insert" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_update" ON promo_tasks;
DROP POLICY IF EXISTS "promo_anon_delete" ON promo_tasks;

CREATE POLICY "promo_anon_select" ON promo_tasks FOR SELECT USING (true);
CREATE POLICY "promo_anon_insert" ON promo_tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "promo_anon_update" ON promo_tasks FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "promo_anon_delete" ON promo_tasks FOR DELETE USING (true);

-- 「Success. No rows returned」でOK。
