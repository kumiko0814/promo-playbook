// ============================================================
// Merone プロモーション進行ToDo  Supabase 設定
// ============================================================
// Re:alize / ナーチャリング共有ボードと同じ Supabase プロジェクトに相乗り。
// くみこがやることは「setup.html の SQL を1回貼るだけ」。
// URL / anonKey はそのままで OK。
//
// プロモごとに進捗を分けたいときは URL に ?promo=xxx を付ける。
//   例）?promo=smasell-2026-08  /  ?promo=famm-2026-09
//   未指定時は default（共通ボード）。
// ============================================================

const SUPABASE_CONFIG = {
  url: 'https://inrvprlyobghviklulcv.supabase.co',
  anonKey: 'sb_publishable_ZrCNcsRHMci-l7Fns8QtIA_X22XZGJp',

  runId: (function () {
    try {
      return (new URLSearchParams(location.search).get('promo') || 'default')
        .toLowerCase().replace(/[^a-z0-9_\-]/g, '').slice(0, 40) || 'default';
    } catch (e) { return 'default'; }
  })(),

  get enabled() { return !!(this.url && this.anonKey); }
};
