#!/usr/bin/env bash
# Unified image optimization script - converts images to WebP, updates markdown references, and removes originals.
#
# By default (Full Workflow mode):
#  1. Finds PNG/JPG/JPEG/GIF images larger than the size threshold
#  2. Converts them to optimized WebP (only if savings meet threshold)
#  3. Updates all markdown references to use the new WebP image
#  4. Removes the original image
#
# Use --convert-only for just WebP generation without updating markdown or removing originals.
#
# Processes images in batches (default 10 per run) to allow review between batches.
# Requires ImageMagick 'magick' or 'convert' on PATH (auto-installs if missing).
#
# Usage:
#   ./optimize-images.sh [OPTIONS]
#
# Options:
#   --root DIR             Root directory to scan (default: content/posts)
#   --size-threshold KB    Only process images larger than this (default: 100)
#   --max-dimension PX     Maximum width/height after resize (default: 1600)
#   --quality N            WebP quality setting (default: 82)
#   --min-savings-percent N  Minimum percentage reduction to keep WebP (default: 10)
#   --min-savings-kb N     Minimum KB reduction to keep WebP (default: 15)
#   --batch-size N         Number of images per batch (default: 10, 0 for all)
#   --convert-only         Only create WebP files, don't update markdown or remove originals
#   --keep-original        Keep original files after conversion
#   --force                Re-process images even if WebP already exists
#   --include-gif          Include GIF files in processing
#   --dry-run              Show what would be done without making changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
ROOT=""
SIZE_THRESHOLD=100
MAX_DIMENSION=1600
QUALITY=82
MIN_SAVINGS_PERCENT=10
MIN_SAVINGS_KB=15
BATCH_SIZE=10
CONVERT_ONLY=false
KEEP_ORIGINAL=false
FORCE=false
INCLUDE_GIF=false
DRY_RUN=false

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
GRAY='\033[90m'
WHITE='\033[37m'
RESET='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)            ROOT="$2"; shift 2 ;;
        --size-threshold)  SIZE_THRESHOLD="$2"; shift 2 ;;
        --max-dimension)   MAX_DIMENSION="$2"; shift 2 ;;
        --quality)         QUALITY="$2"; shift 2 ;;
        --min-savings-percent) MIN_SAVINGS_PERCENT="$2"; shift 2 ;;
        --min-savings-kb)  MIN_SAVINGS_KB="$2"; shift 2 ;;
        --batch-size)      BATCH_SIZE="$2"; shift 2 ;;
        --convert-only)    CONVERT_ONLY=true; shift ;;
        --keep-original)   KEEP_ORIGINAL=true; shift ;;
        --force)           FORCE=true; shift ;;
        --include-gif)     INCLUDE_GIF=true; shift ;;
        --dry-run)         DRY_RUN=true; shift ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [OPTIONS] (see script header for details)"
            exit 1
            ;;
    esac
done

# Set default root
if [[ -z "$ROOT" ]]; then
    ROOT="$SCRIPT_DIR/content/posts"
fi

if [[ ! -d "$ROOT" ]]; then
    echo -e "${RED}Root path not found: $ROOT${RESET}"
    exit 1
fi

# Ensure ImageMagick is available
ensure_imagemagick() {
    if command -v magick &>/dev/null; then
        MAGICK_CMD="magick"
        return 0
    elif command -v convert &>/dev/null; then
        MAGICK_CMD="convert"
        return 0
    fi

    echo -e "\n${YELLOW}ImageMagick not found. Attempting to install...${RESET}"

    if command -v apt-get &>/dev/null; then
        echo -e "${CYAN}Installing ImageMagick via apt-get...${RESET}"
        sudo apt-get update -qq && sudo apt-get install -y -qq imagemagick webp
        if command -v magick &>/dev/null; then
            MAGICK_CMD="magick"
            echo -e "${GREEN}ImageMagick installed successfully!${RESET}"
            return 0
        elif command -v convert &>/dev/null; then
            MAGICK_CMD="convert"
            echo -e "${GREEN}ImageMagick installed successfully!${RESET}"
            return 0
        fi
    fi

    echo -e "${RED}ImageMagick is required but could not be automatically installed."
    echo ""
    echo "Please install manually:"
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick webp"
    echo "  macOS:         brew install imagemagick webp"
    echo "  Arch:          sudo pacman -S imagemagick libwebp"
    echo ""
    echo "After installation, run this script again.${RESET}"
    exit 1
}

# Calculate savings
get_savings() {
    local orig_bytes=$1
    local new_bytes=$2

    local saved_bytes=$((orig_bytes - new_bytes))
    local saved_kb=$(awk "BEGIN {printf \"%.1f\", $saved_bytes / 1024}")
    local percent=0
    if [[ $orig_bytes -gt 0 ]]; then
        percent=$(awk "BEGIN {printf \"%.1f\", ($saved_bytes * 100) / $orig_bytes}")
    fi

    SAVINGS_KB="$saved_kb"
    SAVINGS_PERCENT="$percent"

    # Check threshold (using integer comparison for simplicity)
    local saved_kb_int=${saved_kb%.*}
    local percent_int=${percent%.*}
    saved_kb_int=${saved_kb_int:-0}
    percent_int=${percent_int:-0}

    if [[ $saved_kb_int -ge $MIN_SAVINGS_KB ]] || [[ $percent_int -ge $MIN_SAVINGS_PERCENT ]]; then
        MEETS_THRESHOLD=true
    else
        MEETS_THRESHOLD=false
    fi
}

# Ensure ImageMagick
ensure_imagemagick

# Build find pattern for extensions
FIND_PATTERN="-iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg'"
if [[ "$INCLUDE_GIF" == true ]]; then
    FIND_PATTERN="$FIND_PATTERN -o -iname '*.gif'"
fi

# Find candidate images above size threshold, sorted by size descending
mapfile -t ALL_FILES < <(eval "find '$ROOT' -type f \( $FIND_PATTERN \)" 2>/dev/null | sort)

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No matching image files found.${RESET}"
    exit 0
fi

# Filter by size threshold (in bytes)
THRESHOLD_BYTES=$((SIZE_THRESHOLD * 1024))
ABOVE_THRESHOLD=()
for f in "${ALL_FILES[@]}"; do
    fsize=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
    if [[ $fsize -gt $THRESHOLD_BYTES ]]; then
        ABOVE_THRESHOLD+=("$f")
    fi
done

if [[ ${#ABOVE_THRESHOLD[@]} -eq 0 ]]; then
    echo -e "${GREEN}No images larger than ${SIZE_THRESHOLD} KB found. Nothing to optimize!${RESET}"
    exit 0
fi

# Sort by size descending
mapfile -t ABOVE_THRESHOLD < <(
    for f in "${ABOVE_THRESHOLD[@]}"; do
        fsize=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
        echo "$fsize $f"
    done | sort -rn | awk '{print $2}'
)

# Pre-filter: remove images that already have WebP (unless --force)
CANDIDATES=()
SKIPPED_COUNT=0
for f in "${ABOVE_THRESHOLD[@]}"; do
    webp_path="${f%.*}.webp"
    if [[ "$FORCE" == true ]] || [[ ! -f "$webp_path" ]]; then
        CANDIDATES+=("$f")
    else
        ((SKIPPED_COUNT++)) || true
    fi
done

if [[ $SKIPPED_COUNT -gt 0 ]]; then
    echo -e "${GRAY}${SKIPPED_COUNT} images already have WebP and will be skipped (use --force to re-process).${RESET}"
fi

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo -e "${GREEN}All images above threshold already have WebP files. Nothing to optimize!${RESET}"
    echo -e "${GRAY}(Use --force to re-process existing WebP files)${RESET}"
    exit 0
fi

# Apply batch limit
TOTAL_CANDIDATES=${#CANDIDATES[@]}
if [[ $BATCH_SIZE -gt 0 ]] && [[ $TOTAL_CANDIDATES -gt $BATCH_SIZE ]]; then
    CANDIDATES=("${CANDIDATES[@]:0:$BATCH_SIZE}")
fi

# Display header
echo ""
echo -e "${CYAN}Image Optimization${RESET}"
echo -e "${CYAN}==================================================${RESET}"
MODE="Full Workflow"
if [[ "$CONVERT_ONLY" == true ]]; then MODE="Convert Only"; fi
echo -e "${WHITE}Mode:        ${MODE}${RESET}"
echo -e "${WHITE}Batch:       ${#CANDIDATES[@]} of ${TOTAL_CANDIDATES} images needing optimization (>${SIZE_THRESHOLD} KB)${RESET}"
echo -e "${WHITE}Quality:     ${QUALITY}${RESET}"
echo -e "${WHITE}Max Size:    ${MAX_DIMENSION}px${RESET}"
echo -e "${WHITE}Min Savings: ${MIN_SAVINGS_PERCENT}% or ${MIN_SAVINGS_KB} KB${RESET}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[DRY RUN] No changes will be made.${RESET}"
fi
echo ""

# Track results
declare -a RESULT_ACTIONS=()
declare -a RESULT_SOURCES=()
declare -a RESULT_ORIGKB=()
declare -a RESULT_NEWKB=()
declare -a RESULT_SAVEDKB=()
declare -a RESULT_PERCENT=()
declare -a RESULT_MDUPDATES=()

CREATED_COUNT=0
WOULD_CREATE_COUNT=0
NO_BENEFIT_COUNT=0
FAILED_COUNT=0
TOTAL_SAVED_KB=0
POTENTIAL_KB=0
TOTAL_MD_UPDATES=0

PROCESSED_COUNT=0

for file in "${CANDIDATES[@]}"; do
    file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    size_kb=$(awk "BEGIN {printf \"%.1f\", $file_size / 1024}")
    webp_path="${file%.*}.webp"
    webp_name=$(basename "$webp_path")
    relative_path="${file#$ROOT/}"

    ((PROCESSED_COUNT++)) || true
    echo -e "${CYAN}$(printf '%6s' "$size_kb") KB  ${relative_path}${RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        tmp_file=$(mktemp /tmp/optimize-XXXXXX.webp)
        if $MAGICK_CMD "$file" -strip -resize "${MAX_DIMENSION}x${MAX_DIMENSION}>" \
            -quality "$QUALITY" -define webp:method=6 "$tmp_file" 2>/dev/null; then

            new_bytes=$(stat -c%s "$tmp_file" 2>/dev/null || stat -f%z "$tmp_file" 2>/dev/null)
            get_savings "$file_size" "$new_bytes"

            if [[ "$MEETS_THRESHOLD" == true ]]; then
                echo -e "  ${GREEN}-> Would save ${SAVINGS_KB} KB (${SAVINGS_PERCENT}%)${RESET}"
                ((WOULD_CREATE_COUNT++)) || true
                POTENTIAL_KB=$(awk "BEGIN {printf \"%.1f\", $POTENTIAL_KB + $SAVINGS_KB}")
                RESULT_ACTIONS+=("WouldCreate")
            else
                echo -e "  ${GRAY}-> No benefit (${SAVINGS_PERCENT}% savings below threshold)${RESET}"
                ((NO_BENEFIT_COUNT++)) || true
                RESULT_ACTIONS+=("NoBenefit")
            fi

            new_kb=$(awk "BEGIN {printf \"%.1f\", $new_bytes / 1024}")
            RESULT_SOURCES+=("$relative_path")
            RESULT_ORIGKB+=("$size_kb")
            RESULT_NEWKB+=("$new_kb")
            RESULT_SAVEDKB+=("$SAVINGS_KB")
            RESULT_PERCENT+=("$SAVINGS_PERCENT")
            RESULT_MDUPDATES+=(0)
        else
            echo -e "  ${RED}-> Error during dry-run conversion${RESET}"
            RESULT_ACTIONS+=("Failed")
            RESULT_SOURCES+=("$relative_path")
            RESULT_ORIGKB+=("$size_kb")
            RESULT_NEWKB+=("")
            RESULT_SAVEDKB+=(0)
            RESULT_PERCENT+=(0)
            RESULT_MDUPDATES+=(0)
            ((FAILED_COUNT++)) || true
        fi
        rm -f "$tmp_file"
        continue
    fi

    # Actual conversion
    if $MAGICK_CMD "$file" -strip -resize "${MAX_DIMENSION}x${MAX_DIMENSION}>" \
        -quality "$QUALITY" -define webp:method=6 "$webp_path" 2>/dev/null; then

        if [[ ! -f "$webp_path" ]]; then
            echo -e "  ${RED}x WebP creation failed${RESET}"
            RESULT_ACTIONS+=("Failed")
            RESULT_SOURCES+=("$relative_path")
            RESULT_ORIGKB+=("$size_kb")
            RESULT_NEWKB+=("")
            RESULT_SAVEDKB+=(0)
            RESULT_PERCENT+=(0)
            RESULT_MDUPDATES+=(0)
            ((FAILED_COUNT++)) || true
            continue
        fi

        new_bytes=$(stat -c%s "$webp_path" 2>/dev/null || stat -f%z "$webp_path" 2>/dev/null)
        get_savings "$file_size" "$new_bytes"

        if [[ "$MEETS_THRESHOLD" != true ]]; then
            echo -e "  ${GRAY}x No benefit (${SAVINGS_PERCENT}% / ${SAVINGS_KB} KB below threshold) - removing WebP${RESET}"
            rm -f "$webp_path"
            new_kb=$(awk "BEGIN {printf \"%.1f\", $new_bytes / 1024}")
            RESULT_ACTIONS+=("NoBenefit")
            RESULT_SOURCES+=("$relative_path")
            RESULT_ORIGKB+=("$size_kb")
            RESULT_NEWKB+=("$new_kb")
            RESULT_SAVEDKB+=("$SAVINGS_KB")
            RESULT_PERCENT+=("$SAVINGS_PERCENT")
            RESULT_MDUPDATES+=(0)
            ((NO_BENEFIT_COUNT++)) || true
            continue
        fi

        new_kb=$(awk "BEGIN {printf \"%.1f\", $new_bytes / 1024}")
        echo -e "  ${GREEN}+ Created: ${new_kb} KB (saved ${SAVINGS_KB} KB, ${SAVINGS_PERCENT}%)${RESET}"

        md_updates=0

        # Full workflow: update markdown references
        if [[ "$CONVERT_ONLY" != true ]]; then
            original_name=$(basename "$file")
            dir_name=$(dirname "$file")

            # Find markdown files to update
            md_files=()
            if [[ -f "$dir_name/index.md" ]]; then
                md_files=("$dir_name/index.md")
            else
                # Fallback: check all .md files in the same directory
                while IFS= read -r -d '' mf; do
                    md_files+=("$mf")
                done < <(find "$dir_name" -maxdepth 1 -name '*.md' -type f -print0 2>/dev/null)
            fi

            for md_file in "${md_files[@]}"; do
                if grep -qi "$original_name" "$md_file" 2>/dev/null; then
                    # Case-insensitive replace of original filename with webp filename
                    sed -i "s/${original_name}/${webp_name}/gI" "$md_file"
                    ((md_updates++)) || true
                fi
            done

            if [[ $md_updates -gt 0 ]]; then
                echo -e "  ${GREEN}+ Updated: ${md_updates} markdown file(s)${RESET}"
            fi

            # Remove original (unless --keep-original)
            if [[ "$KEEP_ORIGINAL" != true ]]; then
                rm -f "$file"
                echo -e "  ${GREEN}+ Removed original${RESET}"
            fi
        fi

        RESULT_ACTIONS+=("Created")
        RESULT_SOURCES+=("$relative_path")
        RESULT_ORIGKB+=("$size_kb")
        RESULT_NEWKB+=("$new_kb")
        RESULT_SAVEDKB+=("$SAVINGS_KB")
        RESULT_PERCENT+=("$SAVINGS_PERCENT")
        RESULT_MDUPDATES+=("$md_updates")

        ((CREATED_COUNT++)) || true
        TOTAL_SAVED_KB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_SAVED_KB + $SAVINGS_KB}")
        TOTAL_MD_UPDATES=$((TOTAL_MD_UPDATES + md_updates))
    else
        echo -e "  ${RED}x Error during conversion${RESET}"
        RESULT_ACTIONS+=("Failed")
        RESULT_SOURCES+=("$relative_path")
        RESULT_ORIGKB+=("$size_kb")
        RESULT_NEWKB+=("")
        RESULT_SAVEDKB+=(0)
        RESULT_PERCENT+=(0)
        RESULT_MDUPDATES+=(0)
        ((FAILED_COUNT++)) || true
    fi
done

# Summary
echo ""
echo -e "${CYAN}==================================================${RESET}"
echo -e "${CYAN}Summary${RESET}"
echo -e "${CYAN}==================================================${RESET}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${GREEN}Would create:  ${WOULD_CREATE_COUNT} WebP files${RESET}"
    echo -e "${GREEN}Would save:    ${POTENTIAL_KB} KB${RESET}"
    echo -e "${GRAY}No benefit:    ${NO_BENEFIT_COUNT} files (below savings threshold)${RESET}"
    if [[ $SKIPPED_COUNT -gt 0 ]]; then
        echo -e "${GRAY}Pre-skipped:   ${SKIPPED_COUNT} files (WebP exists, use --force to re-process)${RESET}"
    fi
else
    echo -e "${GREEN}Created:       ${CREATED_COUNT} WebP files${RESET}"
    echo -e "${GREEN}Saved:         ${TOTAL_SAVED_KB} KB total${RESET}"
    if [[ "$CONVERT_ONLY" != true ]]; then
        echo -e "${GREEN}MD updated:    ${TOTAL_MD_UPDATES} file(s)${RESET}"
    fi
    echo -e "${GRAY}No benefit:    ${NO_BENEFIT_COUNT} files${RESET}"
    if [[ $FAILED_COUNT -gt 0 ]]; then
        echo -e "${RED}Failed:        ${FAILED_COUNT} files${RESET}"
    else
        echo -e "${GRAY}Failed:        ${FAILED_COUNT} files${RESET}"
    fi
fi

# Show detailed results table
RESULT_COUNT=${#RESULT_ACTIONS[@]}
if [[ $RESULT_COUNT -gt 0 ]]; then
    echo ""
    printf "%-12s %6s %8s %8s %8s %4s  %s\n" "Action" "%" "SavedKB" "OrigKB" "NewKB" "MD" "Source"
    printf "%-12s %6s %8s %8s %8s %4s  %s\n" "------" "---" "-------" "------" "-----" "--" "------"
    for ((i = 0; i < RESULT_COUNT; i++)); do
        printf "%-12s %6s %8s %8s %8s %4s  %s\n" \
            "${RESULT_ACTIONS[$i]}" \
            "${RESULT_PERCENT[$i]}" \
            "${RESULT_SAVEDKB[$i]}" \
            "${RESULT_ORIGKB[$i]}" \
            "${RESULT_NEWKB[$i]}" \
            "${RESULT_MDUPDATES[$i]}" \
            "${RESULT_SOURCES[$i]}"
    done
fi

# Next steps
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo -e "${YELLOW}Run without --dry-run to apply changes.${RESET}"
elif [[ $BATCH_SIZE -gt 0 ]] && [[ $TOTAL_CANDIDATES -gt $BATCH_SIZE ]]; then
    remaining=$((TOTAL_CANDIDATES - BATCH_SIZE))
    echo ""
    echo -e "${CYAN}Batch complete. Run again to process remaining ${remaining} images.${RESET}"
fi
