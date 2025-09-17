# Dex-Tux 🐧

A web-based control panel for creating and managing locally hosted domains on Termux. Turn your Android device into a powerful micro-server for development and private projects.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Status](https://img.shields.io/badge/status-in%20development-orange.svg)

---

## 🎯 Core Concept

Dex-Tux leverages the power of **Nginx** running within **Termux** to host multiple websites on a single device. The primary domain, `dex.tux`, serves a user-friendly control panel that allows you to dynamically add, remove, and manage other local domains (like `flipper.tux`, `project-alpha.tux`, etc.) without ever touching the command line.

This creates a perfect, sandboxed environment for web development, testing, or hosting private applications accessible on your local network.

## ✨ Features

-   **Zero-Cost Hosting:** Run a web server directly on your Android device.
-   **Dynamic Domain Management:** A simple web interface (`dex.tux`) to control Nginx virtual hosts.
-   **Multi-Site Support:** Host an unlimited number of custom `.tux` domains.
-   **Lightweight & Portable:** Built on Termux and Nginx, requiring minimal resources.
-   **Extensible:** Provides a solid foundation for adding more features like a file manager or SSL support.

## ⚙️ How It Works

1.  **Termux Server:** An Nginx instance runs on your Android device, listening for HTTP requests on port `8080`.
2.  **Nginx Virtual Hosts:** The `nginx.conf` file is configured with multiple `server` blocks. Each block maps a domain name (`server_name`) to a specific directory on your device.
3.  **Dex-Tux Control Panel:** The `dex.tux` site is a web application (e.g., built with Python/Flask) that can read and write to the `nginx.conf` file. When you add a new domain via the UI, the app automatically generates a new `server` block and reloads Nginx.
4.  **Local DNS Resolution:** To access these sites, client devices on the same network must have their `hosts` file edited to point the `.tux` domains to the IP address of the Termux device.

## 🚀 Getting Started

Follow these steps to get Dex-Tux up and running.

### Prerequisites

-   [Termux](https://f-droid.org/en/packages/com.termux/) installed on your Android device.
-   Your Android device and client computer must be on the **same Wi-Fi network**.

### 1. Server Installation (on Termux)

```bash
# Update packages and install dependencies
pkg update && pkg upgrade
pkg install git nginx python

# Clone the repository
git clone [https://github.com/SullyGreene/Dex-Tux.git](https://github.com/SullyGreene/Dex-Tux.git)

# Navigate into the project directory
cd Dex-Tux

# Run the installer script (this will set up Nginx and dependencies)
bash install.sh

# Start the Dex-Tux server
python app.py
```
2. Client Configuration (on your Computer/Other Device)
To access your .tux domains, you need to tell your computer where to find them.

Find your Termux device's local IP address. In Termux, run:

```Bash

ifconfig
```
Look for the inet address under the wlan0 interface (e.g., 192.168.1.42).

Edit your hosts file with administrator/sudo privileges.

Windows: C:\Windows\System32\drivers\etc\hosts

macOS / Linux: /etc/hosts

Add entries for dex.tux and any other domains you create. Replace YOUR_TERMUX_IP with the IP you just found.

# Dex-Tux Domains
YOUR_TERMUX_IP   dex.tux
YOUR_TERMUX_IP   flipper.tux
3. Access Your Control Panel
Open a web browser on your configured computer and navigate to:

http://dex.tux:8080

You should now see the Dex-Tux control panel, ready to manage your domains!

## 🗺️ Project Roadmap
[ ] Core: Basic web app to add/remove Nginx server blocks.

[ ] UI/UX: A clean, responsive frontend for the control panel.

[ ] Authentication: Add a login page to secure the control panel.

[ ] File Manager: A simple web-based file manager for each domain's directory.

[ ] Local SSL: A feature to generate self-signed SSL certificates for https access.

[ ] One-Click Installers: Add buttons to quickly deploy popular apps (e.g., WordPress).

### 🤝 Contributing
Contributions are welcome! If you have an idea for a new feature or have found a bug, please open an issue or submit a pull request.

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

#### 📜 License
This project is distributed under the MIT License. See LICENSE.txt for more information.
