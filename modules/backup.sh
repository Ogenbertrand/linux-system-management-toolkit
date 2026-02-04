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

Examples:
  lsm backup create /home/user/documents
  lsm backup restore backups/documents_20260203_150000.tar.gz
  lsm backup restore backups/documents_20260203_150000.tar.gz /tmp/restore
  lsm backup list

Configuration:
  Backup directory: Set BACKUP_DIR in config/toolkit.conf (default: ./backups)
  Compression: Set BACKUP_COMPRESSION to gzip, bzip2, xz, or none (default: gzip)

EOF
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
    local source_path="${1:-}"
    
    # Validate source path
    if [[ -z "$source_path" ]]; then
        echo -e "${C_R}Error: Source path is required${C_RST}" >&2
        echo "Usage: lsm backup create <path>" >&2
        return 1
    fi
    
    if [[ ! -e "$source_path" ]]; then
        echo -e "${C_R}Error: Source path does not exist: $source_path${C_RST}" >&2
        return 1
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Generate timestamp and backup filename
    local timestamp=$(date +%Y%m%d_%H%M%S)
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
        ((backup_count++))
        local filename=$(basename "$backup_file")
        local size=$(du -h "$backup_file" | cut -f1)
        local date=$(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file" 2>/dev/null || echo "Unknown")
        
        echo -e "${C_G}$filename${C_RST}"
        echo "  Size: $size"
        echo "  Date: ${date:0:19}"
        echo ""
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.tar.bz2" -o -name "*.tar.xz" -o -name "*.tar" \) -print0 | sort -z)
    
    if [[ $backup_count -eq 0 ]]; then
        echo -e "${C_Y}No backups found in: $BACKUP_DIR${C_RST}"
        echo "Create your first backup with: lsm backup create <path>"
    else
        echo -e "${C_B}Total backups: $backup_count${C_RST}"
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
