#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

info()    { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
success() { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()    { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
error()   { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1"; exit 1; }

cd "$PROJECT_DIR"

# Mint bootstrap
if [ -f "Mintfile" ]; then
    info "Mint bootstrap を実行しています..."
    mint bootstrap
    success "Mint bootstrap 完了"
else
    warn "Mintfile が見つかりません。スキップします。"
fi

# XcodeGen
if [ -f "project.yml" ]; then
    info "XcodeGen でプロジェクトを生成しています..."
    xcodegen generate
    success "プロジェクトを生成しました"
else
    warn "project.yml が見つかりません。XcodeGen をスキップします。"
fi

# SPM resolve
info "SPM パッケージを解決しています..."
xcodebuild -resolvePackageDependencies 2>/dev/null || warn "SPM パッケージ解決をスキップしました"
success "SPM パッケージ解決完了"

echo ""
success "bootstrap 完了！ビルドの準備が整いました。"
