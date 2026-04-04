#!/bin/bash
# 将 rules 和 skills 安装到 ~/.cursor/

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

echo "==> 安装 skills..."
mkdir -p ~/.cursor/skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p ~/.cursor/skills/"$skill_name"
    replace_placeholder "$skill_dir/SKILL.md" ~/.cursor/skills/"$skill_name"/SKILL.md
    echo "    ~/.cursor/skills/$skill_name/SKILL.md"
done

echo ""
echo "完成。"
echo ""
echo "还需手动操作："
echo "  1. 将 cursor-settings-rules.txt 中的内容粘贴到:"
echo "     Cursor → Settings → Rules for AI"
echo "  2. 手动替换 cursor-settings-rules.txt 中的 <CC_PATH> 为: $CC_PATH"
