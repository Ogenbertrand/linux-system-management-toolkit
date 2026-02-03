#!/usr/bin/env bash

################################################################################
# Backup Module
#
# Description: Create timestamped backup archives of directories
# Commands: create, help
################################################################################

set -euo pipefail

backup_help() {
    cat << EOF
Backup Module

Usage: lsm backup <command> [options]

Commands:
  create      - Create a timestamped backup archive
  help        - Show this help message

Options (create):
  <source_dir> <dest_dir> [compression]

Compression:
  gzip        - Create a .tar.gz archive
  none        - Create a .tar archive (default)

Examples:
  lsm backup create /home/user /var/backups
  lsm backup create /home/user /var/backups gzip
  lsm backup help
EOF
}

backup_create() {
    local source_dir="${1:-}"
    local dest_dir="${2:-}"
    local compression="${3:-none}"

    if [[ -z "$source_dir" || -z "$dest_dir" ]]; then
        echo "Error: source and destination directories are required." >&2
        backup_help
        return 1
    fi

    if ! command -v tar &> /dev/null; then
        echo "Error: tar is not installed." >&2
        return 1
    fi

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: source directory does not exist: $source_dir" >&2
        return 1
    fi

    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || {
            echo "Error: failed to create destination directory: $dest_dir" >&2
            return 1
        }
    fi

    local timestamp archive_name archive_path source_parent source_base
    timestamp=$(date +"%Y%m%d_%H%M%S")
    source_parent=$(dirname "$source_dir")
    source_base=$(basename "$source_dir")

    case "$compression" in
        gzip)
            archive_name="${source_base}_${timestamp}.tar.gz"
            archive_path="${dest_dir}/${archive_name}"
            tar -czf "$archive_path" -C "$source_parent" "$source_base"
            ;;
        none|"")
            archive_name="${source_base}_${timestamp}.tar"
            archive_path="${dest_dir}/${archive_name}"
            tar -cf "$archive_path" -C "$source_parent" "$source_base"
            ;;
        *)
            echo "Error: unsupported compression option '$compression'. Use 'gzip' or 'none'." >&2
            return 1
            ;;
    esac

    if [[ ! -f "$archive_path" || ! -s "$archive_path" ]]; then
        echo "Error: backup creation failed." >&2
        return 1
    fi

    echo "Backup created: $archive_path"
}
