# VPS Statistics to Discord

This script collects system statistics from a VPS and sends them to a Discord channel using a webhook. It supports multiple Linux distributions and macOS, and includes error handling and automatic dependency installation.

## Features

- Collects system statistics including CPU, RAM, Disk usage, Network Bandwidth, Uptime, and more.
- Supports various Linux distributions (Ubuntu, Debian, CentOS, RedHat, Fedora, Arch) and macOS.
- Automatically installs missing dependencies if required.
- Sends statistics to a Discord channel using a webhook.

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/DevX-77/vps-stats-discord.git
   cd vps-stats-discord
   ```

2. **Ensure Dependencies:**

   Make sure you have `curl`, `awk`, `ping`, and `ifstat` installed. The script will attempt to install any missing dependencies automatically based on your OS.

3. **Configure the Script:**

Open `script.sh` and set your own Discord `WebHook` URL 

4. **Run the Script:**

  ```bash
   bash script.sh
   ```

## Usage

- **Discord Embed**: The script formats the collected statistics into a Discord embed message. The message includes:
  - CPU model
  - Operating System
  - Uptime
  - RAM usage and total RAM
  - Disk usage and total disk
  - Network bandwidth (RX/TX)
  - Server response time
  - Number of running processes

- **Error Handling**: The script provides error messages if any statistics cannot be collected or if dependencies are missing.

## Troubleshooting

- **Error Messages**: If you see errors related to missing commands or failed statistics collection, ensure all required commands are installed and verify the script’s permissions.
- **Dependency Installation**: The script tries to install missing dependencies automatically. If automatic installation fails, you may need to install them manually using your package manager.

## Contributing

Feel free to fork the repository and submit pull requests with improvements or fixes. For any issues, please open a GitHub issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
