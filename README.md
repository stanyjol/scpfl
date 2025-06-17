# scpfl - SCP File Copier

A bash script that copies files from multiple servers to a local directory using SCP, adding server names as suffixes to the copied files.

## Features

- Copy files from multiple servers in one command
- Automatically adds server name suffix to copied files
- Interactive password prompts for each server
- Configurable destination directory
- Progress tracking and summary reporting
- Support for comments in server configuration file
- Error handling and validation

## Requirements

- `scp` command available on the system
- SSH access to target servers
- `~/Sourceservers.txt` configuration file

## Setup

1. Create the server configuration file `~/Sourceservers.txt` with the following format:

```
# Format: server_name:username@hostname:/path/to/source/file
server1:user@192.168.1.10:/var/log/application.log
server2:admin@example.com:/home/admin/config.txt
server3:root@10.0.0.5:/etc/nginx/nginx.conf
```

2. Make the script executable:

```bash
chmod +x scpfl.sh
```

## Usage

```bash
# Copy files to default directory (./downloaded_files)
./scpfl.sh

# Copy files to specific directory
./scpfl.sh /path/to/destination

# Show help
./scpfl.sh --help
```

## Configuration File Format

The `~/Sourceservers.txt` file should contain one entry per line with the format:

```
server_name:username@hostname:/path/to/source/file
```

Where:
- `server_name`: A unique identifier for the server (used as file suffix)
- `username@hostname`: SSH connection details
- `/path/to/source/file`: Full path to the file on the remote server

### Example Configuration

```
webserver1:deploy@web1.example.com:/var/log/nginx/access.log
database:admin@db.example.com:/var/lib/mysql/mysql.log
backup:root@backup.local:/home/backup/daily.tar.gz
```

## Output

Files are copied with the following naming convention:
```
original_filename-server_name
```

For example, if copying `config.txt` from `server1`, the local file will be named `config.txt-server1`.

## Features

- **Interactive Authentication**: The script will prompt for passwords when needed
- **Progress Tracking**: Shows which server is being processed
- **Error Handling**: Continues processing other servers if one fails
- **Summary Report**: Shows total processed, successful, and failed copies
- **Directory Creation**: Automatically creates destination directory if it doesn't exist
- **File Listing**: Shows all downloaded files at the end

## Example Output

```
=== SCP File Copier ===
Destination directory: ./downloaded_files
Servers file: /home/user/Sourceservers.txt

Creating destination directory: ./downloaded_files
Processing server: webserver1
Copying from webserver1: deploy@web1.example.com:/var/log/nginx/access.log -> ./downloaded_files/access.log-webserver1
deploy@web1.example.com's password: 
✓ Successfully copied from webserver1
  File saved as: ./downloaded_files/access.log-webserver1

=== Summary ===
Total servers processed: 1
Successful copies: 1
Failed copies: 0

Files copied to: ./downloaded_files
Listing downloaded files:
total 12
drwxr-xr-x 2 user user 4096 Jun 17 12:30 .
drwxr-xr-x 3 user user 4096 Jun 17 12:30 ..
-rw-r--r-- 1 user user 1234 Jun 17 12:30 access.log-webserver1
```
