#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 KriptoGraf Pro — Build Başlıyor..."
echo "📂 Dizin: $PROJECT_DIR"

# ── Flutter SDK ───────────────────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR/.flutter_sdk" ]; then
  echo "📦 Flutter SDK indiriliyor..."
  git clone https://github.com/flutter/flutter.git \
    -b stable --depth 1 -c core.autocrlf=false \
    "$PROJECT_DIR/.flutter_sdk"
fi
export PATH="$PROJECT_DIR/.flutter_sdk/bin:$PATH"
echo "✓ $(flutter --version 2>&1 | head -1)"

# ── Frontend Build ────────────────────────────────────────────────────────
cd "$PROJECT_DIR/frontend"
echo ""
echo "📦 Bağımlılıklar..."
flutter config --enable-web
flutter pub get

echo "🔍 Analiz..."
ERROR_COUNT=$(flutter analyze 2>&1 | grep -c "^\s*error" || true)
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo "❌ $ERROR_COUNT hata var — build durdu."
  flutter analyze 2>&1 | grep "^\s*error"
  exit 1
fi

echo "🔨 Web build (release)..."
flutter build web \
  --release \
  --no-tree-shake-icons \
  --dart-define=BACKEND_URL="${BACKEND_URL:-https://kriptograf-backend.onrender.com}"

echo ""
echo "📊 Build boyutu:"
du -sh build/web/ 2>/dev/null || true

# ── Cloudflare Worker Deploy (opsiyonel) ──────────────────────────────────
if command -v wrangler &> /dev/null; then
  echo ""
  echo "☁️  Cloudflare Worker deploy ediliyor..."
  cd "$PROJECT_DIR/cloudflare_worker"
  wrangler deploy
  echo "✓ Worker deploy edildi"
else
  echo ""
  echo "ℹ️  Cloudflare Worker için: npm install -g wrangler && wrangler login"
  echo "   Sonra: cd cloudflare_worker && wrangler deploy"
fi

echo ""
echo "✅ Build tamamlandı!"
echo "   Frontend: $PROJECT_DIR/frontend/build/web/"
echo "   Worker:   $PROJECT_DIR/cloudflare_worker/"
