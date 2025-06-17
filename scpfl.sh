#!/bin/bash

# Script: scpfl.sh
# Purpose: Copy files from multiple servers to local directory and add suffix to filename by server name
# Usage: ./scpfl.sh [OPTIONS] [destination_directory]
# Requirements: ~/Sourceservers.txt file with supported formats

# Note: Not using 'set -e' to allow script to continue on individual server failures

# Configuration
SERVERS_FILE="$HOME/Sourceservers.txt"
DEFAULT_DEST_DIR="./downloaded_files"
DEFAULT_USER=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] [destination_directory]"
    echo ""
    echo "This script copies files from multiple servers using SCP."
    echo "Server list and source paths should be defined in ~/Sourceservers.txt"
    echo ""
    echo "Supported formats in ~/Sourceservers.txt:"
    echo "  1. Full format: user@hostname:/path/to/source/file"
    echo "  2. Short format: @hostname:/path/to/source/file (requires --user option)"
    echo ""
    echo "Options:"
    echo "  --user USERNAME    Default username for entries in short format (@hostname:path)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default destination"
    echo "  $0 /tmp/downloads                     # Specify destination directory"
    echo "  $0 --user admin /tmp/downloads        # Use 'admin' as default user"
    echo ""
    echo "Sourceservers.txt examples:"
    echo "  deploy@web1.example.com:/var/log/nginx/access.log"
    echo "  @db.example.com:/var/lib/mysql/mysql.log"
    echo ""
    echo "Arguments:"
    echo "  destination_directory  Local directory to store copied files (default: ./downloaded_files)"
    exit 1
}

# Function to validate servers file
validate_servers_file() {
    if [[ ! -f "$SERVERS_FILE" ]]; then
        echo "Error: Servers file not found at $SERVERS_FILE"
        echo "Please create the file with the following formats:"
        echo "  user@hostname:/path/to/source/file"
        echo "  @hostname:/path/to/source/file (requires --user option)"
        exit 1
    fi
    
    if [[ ! -s "$SERVERS_FILE" ]]; then
        echo "Error: Servers file $SERVERS_FILE is empty"
        exit 1
    fi
}

# Function to copy file from a server
copy_from_server() {
    local scp_source="$1"
    local dest_dir="$2"
    
    # Extract hostname from scp_source for server name
    local hostname=$(echo "$scp_source" | sed 's/.*@\([^:]*\):.*/\1/')
    
    # Extract filename from source path
    local source_path=$(echo "$scp_source" | sed 's/.*://')
    local source_filename=$(basename "$source_path")
    local dest_filename="${source_filename}-${hostname}"
    local dest_path="${dest_dir}/${dest_filename}"
    
    echo "Copying from $hostname: $scp_source -> $dest_path"
    
    # Use scp with options for better user experience
    if scp -o ConnectTimeout=30 -o BatchMode=no "$scp_source" "$dest_path"; then
        echo "✓ Successfully copied from $hostname"
        echo "  File saved as: $dest_path"
    else
        echo "✗ Failed to copy from $hostname"
        return 1
    fi
    
    echo ""
}

# Main function
main() {
    local dest_dir="$DEFAULT_DEST_DIR"
    local default_user="$DEFAULT_USER"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                default_user="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            -*)
                echo "Error: Unknown option $1"
                usage
                ;;
            *)
                # This should be the destination directory
                dest_dir="$1"
                shift
                ;;
        esac
    done
    
    echo "=== SCP File Copier ==="
    echo "Destination directory: $dest_dir"
    echo "Servers file: $SERVERS_FILE"
    if [[ -n "$default_user" ]]; then
        echo "Default user: $default_user"
    fi
    echo ""
    
    # Validate servers file
    validate_servers_file
    
    # Create destination directory if it doesn't exist
    if [[ ! -d "$dest_dir" ]]; then
        echo "Creating destination directory: $dest_dir"
        mkdir -p "$dest_dir"
    fi
    
    # Read servers file and process each entry
    local success_count=0
    local total_count=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        local scp_source=""
        
        # Parse line formats:
        # 1. Full format: user@hostname:/path/to/file
        # 2. Short format: @hostname:/path/to/file
        if [[ "$line" =~ ^[^@]+@[^:]+:.+ ]]; then
            # Full format: user@hostname:/path/to/file
            scp_source="$line"
        elif [[ "$line" =~ ^@[^:]+:.+ ]]; then
            # Short format: @hostname:/path/to/file
            if [[ -z "$default_user" ]]; then
                echo "Error: Short format entry '$line' requires --user option"
                echo "Use: $0 --user USERNAME"
                continue
            fi
            # Remove the @ and prepend the default user
            scp_source="${default_user}${line}"
        else
            echo "Warning: Invalid line format: $line"
            echo "Expected formats:"
            echo "  user@hostname:/path/to/file"
            echo "  @hostname:/path/to/file (with --user option)"
            echo ""
            continue
        fi
        
        ((total_count++))
        
        # Extract hostname for display
        local hostname=$(echo "$scp_source" | sed 's/.*@\([^:]*\):.*/\1/')
        echo "Processing server: $hostname"
        
        if copy_from_server "$scp_source" "$dest_dir"; then
            ((success_count++))
        fi
    done < "$SERVERS_FILE"
    
    # Summary
    echo "=== Summary ==="
    echo "Total servers processed: $total_count"
    echo "Successful copies: $success_count"
    echo "Failed copies: $((total_count - success_count))"
    
    if [[ $success_count -gt 0 ]]; then
        echo ""
        echo "Files copied to: $dest_dir"
        echo "Listing downloaded files:"
        ls -la "$dest_dir"
    fi
}

# Run main function with all arguments
main "$@"
