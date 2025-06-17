#!/bin/bash

# Script: scpfl.sh
# Purpose: Copy files from multiple servers to local directory and add suffix to filename by server name
# Usage: ./scpfl.sh [local_destination_directory]
# Requirements: ~/Sourceservers.txt file with format: server_name:username@hostname:/path/to/source/file

# Note: Not using 'set -e' to allow script to continue on individual server failures

# Configuration
SERVERS_FILE="$HOME/Sourceservers.txt"
DEFAULT_DEST_DIR="./downloaded_files"

# Function to display usage
usage() {
    echo "Usage: $0 [destination_directory]"
    echo ""
    echo "This script copies files from multiple servers using SCP."
    echo "Server list and source paths should be defined in ~/Sourceservers.txt"
    echo ""
    echo "Format of ~/Sourceservers.txt:"
    echo "server_name:username@hostname:/path/to/source/file"
    echo ""
    echo "Example:"
    echo "server1:user@192.168.1.10:/var/log/app.log"
    echo "server2:admin@example.com:/home/admin/config.txt"
    echo ""
    echo "Arguments:"
    echo "  destination_directory  Local directory to store copied files (default: ./downloaded_files)"
    exit 1
}

# Function to validate servers file
validate_servers_file() {
    if [[ ! -f "$SERVERS_FILE" ]]; then
        echo "Error: Servers file not found at $SERVERS_FILE"
        echo "Please create the file with the following format:"
        echo "server_name:username@hostname:/path/to/source/file"
        exit 1
    fi
    
    if [[ ! -s "$SERVERS_FILE" ]]; then
        echo "Error: Servers file $SERVERS_FILE is empty"
        exit 1
    fi
}

# Function to copy file from a server
copy_from_server() {
    local server_name="$1"
    local scp_source="$2"
    local dest_dir="$3"
    
    # Extract filename from source path
    local source_filename=$(basename "$scp_source")
    local dest_filename="${source_filename}-${server_name}"
    local dest_path="${dest_dir}/${dest_filename}"
    
    echo "Copying from $server_name: $scp_source -> $dest_path"
    
    # Use scp with options for better user experience
    if scp -o ConnectTimeout=30 -o BatchMode=no "$scp_source" "$dest_path"; then
        echo "✓ Successfully copied from $server_name"
        echo "  File saved as: $dest_path"
    else
        echo "✗ Failed to copy from $server_name"
        return 1
    fi
    
    echo ""
}

# Main function
main() {
    # Parse command line arguments
    local dest_dir="${1:-$DEFAULT_DEST_DIR}"
    
    # Show usage if help is requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
    fi
    
    echo "=== SCP File Copier ==="
    echo "Destination directory: $dest_dir"
    echo "Servers file: $SERVERS_FILE"
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
        
        # Parse line format: server_name:username@hostname:/path/to/file
        if [[ "$line" =~ ^([^:]+):(.+)$ ]]; then
            local server_name="${BASH_REMATCH[1]}"
            local scp_source="${BASH_REMATCH[2]}"
            
            ((total_count++))
            
            echo "Processing server: $server_name"
            if copy_from_server "$server_name" "$scp_source" "$dest_dir"; then
                ((success_count++))
            fi
        else
            echo "Warning: Invalid line format: $line"
            echo "Expected format: server_name:username@hostname:/path/to/file"
            echo ""
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
