#!/bin/bash
# 将 rules、commands、skills 安装到 ~/.cursor/

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 探测 Claude Code 路径（不用 `which cc`，macOS 上 cc 是 C 编译器）
CC_PATH=""
if command -v claude &> /dev/null; then
    CC_PATH=$(which claude)
fi

if [ -z "$CC_PATH" ]; then
    echo "警告: 未找到 cc 或 claude 命令"
    read -p "请手动输入 Claude Code 路径 (或按回车跳过): " CC_PATH
    if [ -z "$CC_PATH" ]; then
        echo "未提供路径，将保持 <CC_PATH> 占位符"
        CC_PATH="<CC_PATH>"
    fi
fi

echo "==> 探测到 cc 路径: $CC_PATH"

# 替换文件中的占位符
replace_placeholder() {
    local src="$1"
    local dst="$2"
    sed "s|<CC_PATH>|$CC_PATH|g" "$src" > "$dst"
}

echo "==> 安装 rules..."
mkdir -p ~/.cursor/rules
cp "$SCRIPT_DIR/rules/ai-dispatch.mdc" ~/.cursor/rules/
echo "    ~/.cursor/rules/ai-dispatch.mdc"

echo "==> 安装 commands..."
mkdir -p ~/.cursor/commands
for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    cp "$cmd_file" ~/.cursor/commands/
    echo "    ~/.cursor/commands/$(basename "$cmd_file")"
done

echo "==> 安装 skills..."
mkdir -p ~/.cursor/skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p ~/.cursor/skills/"$skill_name"
    for md_file in "$skill_dir"*.md; do
        [ -f "$md_file" ] || continue
        replace_placeholder "$md_file" ~/.cursor/skills/"$skill_name"/$(basename "$md_file")
        echo "    ~/.cursor/skills/$skill_name/$(basename "$md_file")"
    done
done

echo ""
echo "完成。"
