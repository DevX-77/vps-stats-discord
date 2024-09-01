#!/bin/bash

# Replace the URL below with your Discord webhook URL
WEBHOOK_URL=""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install missing dependencies based on OS
install_dependency() {
    case "$os_type" in
        Ubuntu|Debian)
            sudo apt-get update && sudo apt-get install -y "$1" || return 1
            ;;
        CentOS|RedHat)
            sudo yum install -y "$1" || return 1
            ;;
        Fedora)
            sudo dnf install -y "$1" || return 1
            ;;
        Arch)
            sudo pacman -S --noconfirm "$1" || return 1
            ;;
        macOS)
            brew install "$1" || return 1
            ;;
        *)
            echo "Automatic installation is not supported for this OS: $os_type"
            return 1
            ;;
    esac
}

# Determine the operating system and distribution
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu)
                    os_type="Ubuntu"
                    ;;
                debian)
                    os_type="Debian"
                    ;;
                centos)
                    os_type="CentOS"
                    ;;
                rhel)
                    os_type="RedHat"
                    ;;
                fedora)
                    os_type="Fedora"
                    ;;
                arch)
                    os_type="Arch"
                    ;;
                *)
                    os_type="Linux"
                    ;;
            esac
        else
            os_type="Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        os_type="Windows"
    else
        os_type="Unknown"
    fi
    echo "$os_type"
}

# Set the OS-specific image URL and command configurations
set_os_specifics() {
    os_type=$(detect_os)
    case "$os_type" in
        Ubuntu|Debian)
            IMAGE_URL="https://assets.ubuntu.com/v1/29985a98-ubuntu-logo32.png"
            RAM_COMMAND="free -m | awk 'NR==2{printf \"%.2f\", \$3*100/\$2}'"
            TOTAL_RAM_COMMAND="free -m | awk 'NR==2{printf \"%.2f\", \$2/1024}'"
            DISK_COMMAND="df -h / | awk 'NR==2 {print \$5}'"
            TOTAL_DISK_COMMAND="df -h / | awk 'NR==2 {print \$2}'"
            CPU_COMMAND="lscpu | grep 'Model name' | awk -F: '{print \$2}' | xargs"
            DISTRO_COMMAND="lsb_release -s -d"
            UPTIME_COMMAND="uptime -p | cut -d ' ' -f 2-"
            PROCESSES_COMMAND="ps aux | wc -l"
            ;;
        macOS)
            IMAGE_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Icon-Mac.png/1200px-Icon-Mac.png"
            RAM_COMMAND="vm_stat | grep 'Pages active' | awk '{printf \"%.2f\", \$3*4096/1024/1024}'"
            TOTAL_RAM_COMMAND="sysctl hw.memsize | awk '{printf \"%.2f\", \$2/1024/1024/1024}'"
            DISK_COMMAND="df -h / | awk 'NR==2 {print \$5}'"
            TOTAL_DISK_COMMAND="df -h / | awk 'NR==2 {print \$2}'"
            CPU_COMMAND="sysctl -n machdep.cpu.brand_string"
            DISTRO_COMMAND="sw_vers -productName"
            UPTIME_COMMAND="uptime | awk -F'( |,|:)+' '{print \$6, \"hours,\", \$7, \"minutes\"}'"
            PROCESSES_COMMAND="ps -e | wc -l"
            ;;
        *)
            echo "Unsupported operating system."
            exit 1
            ;;
    esac
}

# Collect system statistics based on the detected OS
collect_stats() {
    used_ram=$(eval "$RAM_COMMAND" 2>/dev/null)
    total_ram=$(eval "$TOTAL_RAM_COMMAND" 2>/dev/null)
    disk_usage=$(eval "$DISK_COMMAND" 2>/dev/null)
    total_disk=$(eval "$TOTAL_DISK_COMMAND" 2>/dev/null)
    cpu_name=$(eval "$CPU_COMMAND" 2>/dev/null)
    distro_full_name=$(eval "$DISTRO_COMMAND" 2>/dev/null)
    uptime=$(eval "$UPTIME_COMMAND" 2>/dev/null)
    running_processes=$(eval "$PROCESSES_COMMAND" 2>/dev/null)
    
    # For network and ping statistics, use Linux commands as placeholders
    server_response_time=$(ping -c 1 google.com | awk -F '/' 'END {print $5}' 2>/dev/null)
    network_interface=$(ip route | awk '/default/ {print $5}' | head -n 1 2>/dev/null)
    network_bandwidth_usage=$(ifstat -i "$network_interface" 1 1 | awk 'NR==3{printf "%.2f/%.2f", $1, $3}' 2>/dev/null)
}

# Log error messages on the VPS
log_error_message() {
    local error_message="$1"
    echo "**Error Detected**: $error_message" >&2
}

# Log success messages on the VPS
log_success_message() {
    echo "**Statistics Message Sent Successfully!**"
}

# Set OS-specific configurations
set_os_specifics

# Ensure necessary commands are available and install if missing
REQUIRED_COMMANDS=("curl" "awk" "ping" "ifstat" "lsb_release")
missing_dependencies=()
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        echo "Installing missing dependency: $cmd"
        install_dependency "$cmd"
        if [[ $? -ne 0 ]]; then
            missing_dependencies+=("$cmd")
        fi
    fi
done

# If there are missing dependencies, log an error message and exit
if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
    log_error_message "Missing dependencies: ${missing_dependencies[*]}"
    exit 1
fi

# Collect system statistics
collect_stats

# Check for errors in command execution
if [[ -z "$used_ram" || -z "$total_ram" || -z "$disk_usage" || -z "$total_disk" || -z "$cpu_name" || -z "$distro_full_name" || -z "$uptime" || -z "$running_processes" || -z "$server_response_time" || -z "$network_bandwidth_usage" ]]; then
    log_error_message "Failed to collect all system statistics. Please check the commands and system configuration."
    exit 1
fi

# Create JSON data for the Discord embed
timestamp=$(date +%s)
title="VPS SYSTEM INFORMATION ➜ <t:${timestamp}:f>"
json_data=$(cat <<EOF
{
  "embeds": [
    {
      "title": "$title",
      "color": 65407,
      "fields": [
        {
          "name": "CPU",
          "value": "$cpu_name",
          "inline": true
        },
        {
          "name": "Operating System",
          "value": "$distro_full_name",
          "inline": true
        },
        {
          "name": "Uptime",
          "value": "$uptime",
          "inline": true
        },
        {
          "name": "RAM Usage (Used/Total)",
          "value": "$used_ram% / $total_ram GB",
          "inline": true
        },
        {
          "name": "Disk Usage (Used/Total)",
          "value": "$disk_usage / $total_disk",
          "inline": true
        },
        {
          "name": "Network Bandwidth (RX/TX)",
          "value": "$network_bandwidth_usage KiB/s",
          "inline": true
        },
        {
          "name": "Server Response Time",
          "value": "$server_response_time ms",
          "inline": true
        },
        {
          "name": "Running Processes",
          "value": "$running_processes",
          "inline": true
        }
      ],
      "thumbnail": {
        "url": "$IMAGE_URL"
      },
      "footer": {
        "text": "System Statistics"
      }
    }
  ]
}
EOF
)

# Send data to Discord webhook
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$json_data" "$WEBHOOK_URL")

# Check if the message was sent successfully
if [ "$response" -eq 204 ]; then
    log_success_message
else
    log_error_message "Failed to send statistics message. HTTP Response: $response"
fi
