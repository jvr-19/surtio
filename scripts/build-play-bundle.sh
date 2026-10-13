#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f android/key.properties ]; then
  echo "Falta android/key.properties. Configura la clave de subida usando android/key.properties.example." >&2
  exit 1
fi
flutter analyze
flutter test
flutter build appbundle --release
bundle="build/app/outputs/bundle/release/app-release.aab"
if ! unzip -Z1 "$bundle" | rg -q '^META-INF/.*\.(RSA|DSA|EC)$'; then
  echo "El AAB no está firmado. No se puede subir a Google Play." >&2
  exit 1
fi
jarsigner -verify "$bundle"
echo "AAB firmado: $bundle. Verifica certificado, versión y ficha antes de subirlo."
