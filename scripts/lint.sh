#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

info()    { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
success() { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()    { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
error()   { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1"; }

cd "$PROJECT_DIR"
EXIT_CODE=0

# SwiftFormat
info "SwiftFormat を実行しています..."
if command -v mint &>/dev/null && [ -f "Mintfile" ]; then
    SWIFTFORMAT_CMD="mint run swiftformat"
else
    SWIFTFORMAT_CMD="swiftformat"
fi

if $SWIFTFORMAT_CMD . 2>/dev/null; then
    success "SwiftFormat 完了"
else
    warn "SwiftFormat の実行に失敗しました"
    EXIT_CODE=1
fi

# SwiftLint
info "SwiftLint を実行しています..."
if command -v mint &>/dev/null && [ -f "Mintfile" ]; then
    SWIFTLINT_CMD="mint run swiftlint"
else
    SWIFTLINT_CMD="swiftlint"
fi

if $SWIFTLINT_CMD lint --strict --quiet 2>/dev/null; then
    success "SwiftLint 完了（違反なし）"
else
    warn "SwiftLint で違反が検出されました"
    EXIT_CODE=1
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    success "すべてのチェックをパスしました！"
else
    error "一部のチェックで問題が検出されました。上記の出力を確認してください。"
fi
exit $EXIT_CODE
