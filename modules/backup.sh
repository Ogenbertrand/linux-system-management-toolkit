#!/usr/bin/env bash

################################################################################
# Backup Module
# 
# Description: Backup and restore directories and files
# Commands: create, restore, list, help
################################################################################

set -euo pipefail

# Color codes for formatted output
readonly C_RST='\033[0m'      # Reset
readonly C_B='\033[1m'        # Bold
readonly C_G='\033[0;32m'     # Green
readonly C_Y='\033[0;33m'     # Yellow
readonly C_R='\033[0;31m'     # Red
readonly C_C='\033[0;36m'     # Cyan

# Get script base directory to locate config
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
BASE_DIR="$(cd "$(dirname "$(dirname "$SCRIPT_PATH")")" && pwd)"

# Load configuration
CONFIG_FILE="${BASE_DIR}/config/toolkit.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Set defaults if not configured
BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-gzip}"

# Module help function
backup_help() {
    cat << 'EOF'
Backup Management Module

Usage: lsm backup <command> [options]

Commands:
  create <path>              - Create a backup of the specified directory or file
  restore <backup> [target]  - Restore a backup to original or specified location
  list                       - List all available backups
  help                       - Show this help message

Options:
  -h, --help                 Show this help message
  --incremental              Create an incremental snapshot (full restore point via hardlinks)
  --compress                 For incremental snapshots: also create a compressed tar archive artifact
  --no-compress              For incremental snapshots: do not create an archive artifact (default)
  --base <snapshot_dir>      For incremental snapshots: explicitly set the base snapshot directory

Examples:
  lsm backup create /home/user/documents
  lsm backup create --incremental /home/user/documents
  lsm backup create --incremental --compress /home/user/documents
  lsm backup restore backups/documents_20260203_150000.tar.gz
  lsm backup restore backups/documents_20260203_150000.tar.gz /tmp/restore
  lsm backup list

Configuration:
  Backup directory: Set BACKUP_DIR in config/toolkit.conf (default: ./backups)
  Compression: Set BACKUP_COMPRESSION to gzip, bzip2, xz, or none (default: gzip)

EOF
}

_require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${C_R}Error: Required command not found: $cmd${C_RST}" >&2
        return 1
    fi
    return 0
}

_resolve_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$p"
    else
        readlink -f "$p"
    fi
}

_timestamp() {
    date +%Y%m%d_%H%M%S_%N
}

# Get compression flag for tar based on config
_get_compression_flags() {
    case "${BACKUP_COMPRESSION}" in
        gzip)
            echo "z"
            ;;
        bzip2)
            echo "j"
            ;;
        xz)
            echo "J"
            ;;
        none)
            echo ""
            ;;
        *)
            echo "z"  # Default to gzip
            ;;
    esac
}

# Get file extension based on compression
_get_extension() {
    case "${BACKUP_COMPRESSION}" in
        gzip)
            echo ".tar.gz"
            ;;
        bzip2)
            echo ".tar.bz2"
            ;;
        xz)
            echo ".tar.xz"
            ;;
        none)
            echo ".tar"
            ;;
        *)
            echo ".tar.gz"
            ;;
    esac
}

# Create a backup
backup_create() {
    local incremental=false
    local compress_mode=""
    local base_override=""
    local source_path=""

    while [[ ${#} -gt 0 ]]; do
        case "${1:-}" in
            --incremental)
                incremental=true
                shift
                ;;
            --compress)
                compress_mode="compress"
                shift
                ;;
            --no-compress)
                compress_mode="no-compress"
                shift
                ;;
            --base)
                base_override="${2:-}"
                shift 2
                ;;
            -h|--help)
                backup_help
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo -e "${C_R}Error: Unknown option: $1${C_RST}" >&2
                echo "Usage: lsm backup create [--incremental] [--compress|--no-compress] [--base <snapshot_dir>] <path>" >&2
                return 1
                ;;
            *)
                source_path="$1"
                shift
                break
                ;;
        esac
    done

    if [[ -z "$source_path" && ${#} -gt 0 ]]; then
        source_path="$1"
        shift
    fi
    
    # Validate source path
    if [[ -z "$source_path" ]]; then
        echo -e "${C_R}Error: Source path is required${C_RST}" >&2
        echo "Usage: lsm backup create [--incremental] [--compress|--no-compress] [--base <snapshot_dir>] <path>" >&2
        return 1
    fi
    
    if [[ ! -e "$source_path" ]]; then
        echo -e "${C_R}Error: Source path does not exist: $source_path${C_RST}" >&2
        return 1
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    if [[ "$incremental" == true ]]; then
        _require_cmd rsync || return 1

        local timestamp
        timestamp=$(_timestamp)
        local basename
        basename=$(basename "$source_path")
        local series_root="${BACKUP_DIR}/${basename}.lsm"
        local snapshots_dir="${series_root}/snapshots"
        local meta_dir="${series_root}/meta"
        local archives_dir="${series_root}/archives"

        mkdir -p "$snapshots_dir" "$meta_dir"

        local abs_source
        abs_source=$(_resolve_path "$source_path")
        printf '%s\n' "$abs_source" > "${meta_dir}/source_path"
        printf '%s\n' "incremental" > "${meta_dir}/mode"

        local new_snapshot="${snapshots_dir}/${timestamp}"
        mkdir -p "$new_snapshot"
        local new_snapshot_abs
        new_snapshot_abs=$(_resolve_path "$new_snapshot")

        local base_snapshot=""
        if [[ -n "$base_override" ]]; then
            if [[ ! -d "$base_override" ]]; then
                echo -e "${C_R}Error: Base snapshot directory does not exist: $base_override${C_RST}" >&2
                return 1
            fi
            base_snapshot=$(_resolve_path "$base_override")
        elif [[ -L "${snapshots_dir}/latest" || -d "${snapshots_dir}/latest" ]]; then
            if [[ -e "${snapshots_dir}/latest" ]]; then
                base_snapshot=$(_resolve_path "${snapshots_dir}/latest")
            fi
        fi

        echo -e "${C_C}Creating incremental snapshot of: ${C_B}$source_path${C_RST}"
        echo -e "${C_C}Snapshot dir: ${C_B}$new_snapshot${C_RST}"
        if [[ -n "$base_snapshot" ]]; then
            echo -e "${C_C}Base snapshot: ${C_B}$base_snapshot${C_RST}"
        else
            echo -e "${C_C}Base snapshot: ${C_B}(none)${C_RST}"
        fi

        local rsync_source
        local rsync_dest
        local link_dest_arg=()

        if [[ -d "$source_path" ]]; then
            mkdir -p "${new_snapshot}/${basename}"
            rsync_source="${source_path%/}/"
            rsync_dest="${new_snapshot}/${basename}/"
        else
            rsync_source="$source_path"
            rsync_dest="${new_snapshot}/"
        fi

        if [[ -n "$base_snapshot" ]]; then
            if [[ -d "$source_path" ]]; then
                if [[ -d "${base_snapshot}/${basename}" ]]; then
                    link_dest_arg=("--link-dest=${base_snapshot}/${basename}")
                else
                    link_dest_arg=("--link-dest=${base_snapshot}")
                fi
            else
                link_dest_arg=("--link-dest=${base_snapshot}")
            fi
        fi

        if rsync -a --delete "${link_dest_arg[@]}" "$rsync_source" "$rsync_dest" 2>&1; then
            ln -sfn "$new_snapshot_abs" "${snapshots_dir}/latest"

            local do_compress=false
            if [[ "$compress_mode" == "compress" ]]; then
                do_compress=true
            elif [[ "$compress_mode" == "no-compress" ]]; then
                do_compress=false
            else
                do_compress=false
            fi

            if [[ "$do_compress" == true ]]; then
                mkdir -p "$archives_dir"
                local extension
                extension=$(_get_extension)
                local comp_flags
                comp_flags=$(_get_compression_flags)
                local archive_file="${archives_dir}/${basename}_${timestamp}${extension}"

                echo -e "${C_C}Creating archive artifact: ${C_B}$archive_file${C_RST}"
                if ! tar -c${comp_flags}f "$archive_file" -C "$(dirname "$new_snapshot")" "$(basename "$new_snapshot")" 2>&1; then
                    echo -e "${C_R}✗ Error: Failed to create archive artifact${C_RST}" >&2
                    return 1
                fi
            fi

            echo ""
            echo -e "${C_G}✓ Incremental snapshot created successfully!${C_RST}"
            echo -e "  Snapshot: ${C_B}$new_snapshot_abs${C_RST}"
            return 0
        else
            echo -e "${C_R}✗ Error: Failed to create incremental snapshot${C_RST}" >&2
            return 1
        fi
    fi
    
    # Generate timestamp and backup filename
    local timestamp=$(_timestamp)
    local basename=$(basename "$source_path")
    local extension=$(_get_extension)
    local backup_file="${BACKUP_DIR}/${basename}_${timestamp}${extension}"
    
    # Get compression flags
    local comp_flags=$(_get_compression_flags)
    
    echo -e "${C_C}Creating backup of: ${C_B}$source_path${C_RST}"
    echo -e "${C_C}Backup file: ${C_B}$backup_file${C_RST}"
    echo -e "${C_C}Compression: ${C_B}$BACKUP_COMPRESSION${C_RST}"
    echo ""
    
    # Create the backup
    if tar -c${comp_flags}f "$backup_file" -C "$(dirname "$source_path")" "$(basename "$source_path")" 2>&1; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo ""
        echo -e "${C_G}✓ Backup created successfully!${C_RST}"
        echo -e "  File: ${C_B}$backup_file${C_RST}"
        echo -e "  Size: ${C_B}$size${C_RST}"
        return 0
    else
        echo -e "${C_R}✗ Error: Failed to create backup${C_RST}" >&2
        return 1
    fi
}

# Restore a backup
backup_restore() {
    local backup_file="${1:-}"
    local target_dir="${2:-}"
    
    # Validate backup file
    if [[ -z "$backup_file" ]]; then
        echo -e "${C_R}Error: Backup file path is required${C_RST}" >&2
        echo "Usage: lsm backup restore <backup_file> [target_directory]" >&2
        return 1
    fi
    
    if [[ -d "$backup_file" ]]; then
        _require_cmd rsync || return 1

        if [[ ! -r "$backup_file" ]]; then
            echo -e "${C_R}Error: Snapshot directory is not readable: $backup_file${C_RST}" >&2
            return 1
        fi

        if [[ -z "$target_dir" ]]; then
            target_dir="."
            echo -e "${C_Y}No target directory specified. Restoring to current location.${C_RST}"
        else
            mkdir -p "$target_dir"
            echo -e "${C_C}Restoring to: ${C_B}$target_dir${C_RST}"
        fi

        echo -e "${C_C}Restoring from snapshot: ${C_B}$backup_file${C_RST}"
        echo ""

        if rsync -a "${backup_file%/}/" "${target_dir%/}/" 2>&1; then
            echo ""
            echo -e "${C_G}✓ Backup restored successfully!${C_RST}"
            echo -e "  Location: ${C_B}$target_dir${C_RST}"
            return 0
        else
            echo -e "${C_R}✗ Error: Failed to restore snapshot${C_RST}" >&2
            return 1
        fi
    fi

    if [[ ! -f "$backup_file" ]]; then
        echo -e "${C_R}Error: Backup file does not exist: $backup_file${C_RST}" >&2
        return 1
    fi

    if [[ ! -r "$backup_file" ]]; then
        echo -e "${C_R}Error: Backup file is not readable: $backup_file${C_RST}" >&2
        return 1
    fi

    # Validate that it's a tar archive
    echo -e "${C_C}Validating backup archive...${C_RST}"
    if ! tar -tf "$backup_file" > /dev/null 2>&1; then
        echo -e "${C_R}Error: File is not a valid tar archive or is corrupted: $backup_file${C_RST}" >&2
        return 1
    fi
    
    # Determine target directory
    if [[ -z "$target_dir" ]]; then
        # Extract to current directory (will restore with original structure)
        target_dir="."
        echo -e "${C_Y}No target directory specified. Extracting to current location.${C_RST}"
    else
        # Create target directory if it doesn't exist
        mkdir -p "$target_dir"
        echo -e "${C_C}Extracting to: ${C_B}$target_dir${C_RST}"
    fi
    
    echo -e "${C_C}Restoring from: ${C_B}$backup_file${C_RST}"
    echo ""
    
    # Extract the backup
    if tar -xvf "$backup_file" -C "$target_dir" 2>&1; then
        echo ""
        echo -e "${C_G}✓ Backup restored successfully!${C_RST}"
        echo -e "  Location: ${C_B}$target_dir${C_RST}"
        return 0
    else
        echo -e "${C_R}✗ Error: Failed to restore backup${C_RST}" >&2
        return 1
    fi
}

# List available backups
backup_list() {
    echo -e "${C_B}${C_C}Available Backups${C_RST}"
    echo -e "${C_C}=================${C_RST}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${C_Y}No backup directory found at: $BACKUP_DIR${C_RST}"
        echo "Create your first backup with: lsm backup create <path>"
        return 0
    fi
    
    # Find all tar archives in backup directory
    local backup_count=0
    while IFS= read -r -d '' backup_file; do
        ((++backup_count))
        local filename=$(basename "$backup_file")
        local size=$(du -h "$backup_file" | cut -f1)
        local date=$(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file" 2>/dev/null || echo "Unknown")
        
        echo -e "${C_G}$filename${C_RST}"
        echo "  Size: $size"
        echo "  Date: ${date:0:19}"
        echo ""
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.tar.bz2" -o -name "*.tar.xz" -o -name "*.tar" \) -print0 | sort -z)

    # Find incremental series directories
    local series_count=0
    while IFS= read -r -d '' series_dir; do
        ((++series_count))
        local series_name
        series_name=$(basename "$series_dir")

        local latest_target=""
        if [[ -e "${series_dir}/snapshots/latest" ]]; then
            latest_target=$(_resolve_path "${series_dir}/snapshots/latest")
        fi

        local snapshot_total=0
        if [[ -d "${series_dir}/snapshots" ]]; then
            snapshot_total=$(find "${series_dir}/snapshots" -maxdepth 1 -mindepth 1 -type d -printf '.' 2>/dev/null | wc -c | tr -d ' ')
        fi

        echo -e "${C_G}${series_name}${C_RST}"
        echo "  Type: incremental"
        if [[ -n "$latest_target" ]]; then
            echo "  Latest: $(basename "$latest_target")"
        else
            echo "  Latest: (none)"
        fi
        echo "  Snapshots: $snapshot_total"
        echo ""
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "*.lsm" -print0 | sort -z)
    
    if [[ $backup_count -eq 0 && $series_count -eq 0 ]]; then
        echo -e "${C_Y}No backups found in: $BACKUP_DIR${C_RST}"
        echo "Create your first backup with: lsm backup create <path>"
    else
        echo -e "${C_B}Total tar backups: $backup_count${C_RST}"
        echo -e "${C_B}Total incremental series: $series_count${C_RST}"
    fi
    
    return 0
}

# Main dispatcher (not used by current CLI but good for compatibility)
backup_main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        create)
            backup_create "$@"
            ;;
        restore)
            backup_restore "$@"
            ;;
        list)
            backup_list "$@"
            ;;
        help|-h|--help)
            backup_help
            ;;
        *)
            echo "Unknown command: $command"
            backup_help
            exit 1
            ;;
    esac
}
