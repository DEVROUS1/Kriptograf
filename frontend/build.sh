#!/bin/bash
set -euo pipefail
if [ ! -d ".flutter_sdk" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk
fi
export PATH="$PWD/.flutter_sdk/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release --no-tree-shake-icons --dart-define=BACKEND_URL=https://kriptograf-backend.onrender.com
