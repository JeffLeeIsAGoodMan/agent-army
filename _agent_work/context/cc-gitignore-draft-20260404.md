# .gitignore 初稿 - agent-army 项目
# 生成日期: 2026-04-04

# ============================================
# 项目特定 - AI 协作中间文件
# ============================================

# 协作工作目录（中间文件、日志、计划）
_agent_work/

# Cursor 本地配置文件（含敏感本地路径）
cursor-settings-rules-local.txt

# ============================================
# macOS
# ============================================
.DS_Store
.AppleDouble
.LSOverride

# macOS 资源叉
._*

# macOS 目录属性
.Spotlight-V100
.Trashes

# macOS iCloud
*.icloud

# ============================================
# 编辑器 / IDE
# ============================================

# VS Code
.vscode/
*.code-workspace

# Cursor
cursor.toml

# JetBrains
.idea/
*.iml
*.iws
out/

# Sublime Text
*.sublime-project
*.sublime-workspace

# Vim
*.swp
*.swo
*~
.vim/

# Emacs
*~
\#*\#
.#*

# Nano
*.save

# ============================================
# Node.js
# ============================================

# 依赖目录
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# 锁文件（可选，根据团队约定）
# package-lock.json
# yarn.lock

# 构建输出
dist/
build/
.next/
.nuxt/
.out/

# 环境变量
.env
.env.local
.env.*.local

# 缓存
.npm
.eslintcache
.parcel-cache

# ============================================
# Python
# ============================================

# 字节码
__pycache__/
*.py[cod]
*$py.class

# 虚拟环境
venv/
env/
ENV/
.venv/

# pip
pip-log.txt
pip-delete-this-directory.txt

# 分发/打包
*.egg-info/
dist/
build/
*.egg

# Jupyter
.ipynb_checkpoints/
*.ipynb

# pytest
.pytest_cache/
.coverage
htmlcov/

# mypy
.mypy_cache/
.dmypy.json

# ============================================
# 日志与临时文件
# ============================================

*.log
*.log.*
nohup.out

# 临时文件
tmp/
temp/
*.tmp
*.temp
*.bak
*.backup
*.orig

# ============================================
# 其他工具
# ============================================

# Git
*.patch
*.diff

# Docker
.dockerignore

# Terraform
.terraform/
*.tfstate
*.tfstate.*

# 压缩文件
*.zip
*.tar.gz
*.tar
*.rar

# ============================================
# 安全敏感（永不提交）
# ============================================

*.pem
*.key
*.crt
*.p12
*.pfx
secrets.json
credentials.json
*_secrets.*
*_credentials.*
