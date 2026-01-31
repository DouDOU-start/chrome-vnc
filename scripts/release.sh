#!/bin/bash
# 发版脚本 - 创建新版本并推送到 GitHub 触发自动构建
# 用法: ./scripts/release.sh [版本号]
# 示例: ./scripts/release.sh 1.0.0
#       ./scripts/release.sh patch  # 自动递增补丁版本
#       ./scripts/release.sh minor  # 自动递增次版本
#       ./scripts/release.sh major  # 自动递增主版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查是否在 git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "当前目录不是 git 仓库"
fi

# 检查工作目录是否干净
if [[ -n $(git status --porcelain) ]]; then
    warn "工作目录有未提交的更改:"
    git status --short
    echo ""
    read -p "是否继续发版? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "已取消发版"
    fi
fi

# 获取最新的 tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# 解析版本号
parse_version() {
    local version=$1
    version=${version#v}  # 移除 v 前缀
    echo "$version"
}

# 递增版本号
increment_version() {
    local version=$1
    local part=$2

    IFS='.' read -r major minor patch <<< "$version"

    case $part in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

# 获取版本号
VERSION=$1
LATEST_TAG=$(get_latest_tag)
LATEST_VERSION=$(parse_version "$LATEST_TAG")

info "当前最新版本: $LATEST_TAG"

if [[ -z "$VERSION" ]]; then
    echo ""
    echo "请选择版本类型:"
    echo "  1) patch - 补丁版本 (bug 修复)"
    echo "  2) minor - 次版本 (新功能)"
    echo "  3) major - 主版本 (重大更新)"
    echo "  4) 自定义版本号"
    echo ""
    read -p "请输入选项 (1-4): " -n 1 -r
    echo

    case $REPLY in
        1) VERSION="patch" ;;
        2) VERSION="minor" ;;
        3) VERSION="major" ;;
        4)
            read -p "请输入版本号 (如 1.2.3): " VERSION
            ;;
        *)
            error "无效选项"
            ;;
    esac
fi

# 处理版本号
case $VERSION in
    patch|minor|major)
        NEW_VERSION=$(increment_version "$LATEST_VERSION" "$VERSION")
        ;;
    *)
        # 移除可能的 v 前缀
        NEW_VERSION=${VERSION#v}
        # 验证版本号格式
        if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            error "无效的版本号格式: $NEW_VERSION (应为 x.y.z)"
        fi
        ;;
esac

TAG="v${NEW_VERSION}"

# 检查 tag 是否已存在
if git rev-parse "$TAG" >/dev/null 2>&1; then
    error "Tag $TAG 已存在"
fi

echo ""
info "即将创建版本: $TAG"
info "变更内容 (自 $LATEST_TAG 以来):"
echo ""
git log --oneline "$LATEST_TAG"..HEAD 2>/dev/null || git log --oneline -10
echo ""

read -p "确认发布 $TAG? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "已取消发版"
fi

# 创建 tag
info "创建 tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"

# 推送 tag
info "推送 tag 到远程仓库..."
git push origin "$TAG"

success "版本 $TAG 发布成功!"
echo ""
info "GitHub Actions 将自动构建并发布 Docker 镜像"
info "查看构建进度: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo ""
info "发布后可使用以下命令拉取镜像:"
echo "  docker pull ghcr.io/doudou-start/chrome-vnc:${NEW_VERSION}"
echo "  docker pull doudoustart/chrome-vnc:${NEW_VERSION}"
