#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

info()    { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
success() { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()    { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }

cd "$PROJECT_DIR"

# Project name from project.yml
PROJECT_NAME=""
if [ -f "project.yml" ]; then
    PROJECT_NAME=$(grep '^name:' project.yml | head -1 | sed 's/name: *//')
fi

# DerivedData
info "DerivedData を削除しています..."
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -n "$PROJECT_NAME" ]; then
    find "$DERIVED_DATA" -maxdepth 1 -type d -name "${PROJECT_NAME}-*" -exec rm -rf {} + 2>/dev/null || true
    success "DerivedData を削除しました（${PROJECT_NAME}）"
else
    rm -rf "$DERIVED_DATA"
    success "DerivedData を全削除しました"
fi

# SPM local cache
if [ -d ".build" ]; then
    rm -rf .build
    success ".build を削除しました"
fi

# Package.resolved
find . -name "Package.resolved" -not -path "./.git/*" -delete 2>/dev/null || true
success "Package.resolved を削除しました"

# SPM global cache
SPM_CACHE="$HOME/Library/Caches/org.swift.swiftpm"
if [ -d "$SPM_CACHE" ]; then
    rm -rf "$SPM_CACHE"
    success "SPM グローバルキャッシュを削除しました"
fi

# Regenerate .xcodeproj
if [ -f "project.yml" ]; then
    info "XcodeGen でプロジェクトを再生成しています..."
    xcodegen generate
    success "プロジェクトを再生成しました"
fi

# Re-resolve SPM
info "SPM パッケージを再解決しています..."
xcodebuild -resolvePackageDependencies 2>/dev/null || warn "SPM パッケージ解決をスキップしました"

echo ""
success "クリーンアップ完了！"
