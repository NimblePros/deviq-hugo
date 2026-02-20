#!/usr/bin/env bash
# Build script for NimblePros Hugo blog
# Builds the site, runs pagefind indexing, and optionally starts the dev server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCTION=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --production|-p)
            PRODUCTION=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--production|-p]"
            exit 1
            ;;
    esac
done

# Optimize images (skip in production builds)
if [[ "$PRODUCTION" == false ]]; then
    echo -e "\033[36mOptimizing images...\033[0m"
    if [[ -f "$SCRIPT_DIR/optimize-images.sh" ]]; then
        bash "$SCRIPT_DIR/optimize-images.sh"
    else
        echo -e "\033[33moptimize-images.sh not found, skipping image optimization\033[0m"
    fi
fi

# Install npm dependencies
echo -e "\033[36mInstalling npm dependencies...\033[0m"
npm install

# Build CSS with PostCSS/Tailwind
echo -e "\n\033[36mBuilding CSS...\033[0m"
npm run build:css

# Minify CSS for production
if [[ "$PRODUCTION" == true ]]; then
    echo -e "\n\033[36mMinifying CSS for production...\033[0m"
    npx postcss static/css/style.css --use cssnano --no-map -o static/css/style.css
fi

# Build Hugo site
echo -e "\n\033[36mBuilding Hugo site...\033[0m"
if [[ "$PRODUCTION" == true ]]; then
    HUGO_ENVIRONMENT=production hugo --minify --cleanDestinationDir
else
    hugo --cleanDestinationDir
fi

# Build Pagefind search index
echo -e "\n\033[36mBuilding Pagefind search index...\033[0m"
npx --yes pagefind --site public

echo -e "\n\033[32mBuild complete!\033[0m"

if [[ "$PRODUCTION" == false ]]; then
    echo -e "\n\033[36mStarting Hugo dev server...\033[0m"
    hugo server --disableFastRender
fi
