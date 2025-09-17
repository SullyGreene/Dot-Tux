# Dot-Tux 🐧

A web-based control panel to create and manage locally hosted domains on your Android device using Termux. Turn your phone into a powerful, pocket-sized server for development and private projects.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Status](https://img.shields.io/badge/status-in%20development-orange.svg)
![Python Version](https://img.shields.io/badge/python-3.8+-brightgreen.svg)

---


*(The Dot-Tux control panel running in a mobile browser.)*

## 🎯 Core Concept

Dot-Tux leverages the power of **Nginx** and **Python Flask** running within **Termux** to host multiple websites on a single Android device. The primary domain, `dot.tux`, serves a user-friendly web interface that allows you to dynamically add and remove other local domains (like `flipper.tux` or `my-project.tux`) without ever touching the command line again.

This creates a perfect, zero-cost, sandboxed environment for web development, testing, or hosting private applications accessible only on your local network.

## ✨ Features

-   **Zero-Cost Hosting:** Run a real web server directly on your Android device.
-   **Dynamic Domain Management:** A simple web UI (`dot.tux`) to add/remove Nginx sites on the fly.
-   **Automated Setup:** A single `install.sh` script handles all dependencies and configuration.
-   **Boots on Start:** Integrates with Termux:Boot to launch the server automatically when your device starts.
-   **Lightweight & Portable:** Built on a minimal stack, requiring very few resources.
-   **Safe Reloads:** Includes configuration checks to prevent broken Nginx configs from being loaded.

## ⚙️ How It Works

1.  **Termux Server:** An Nginx instance runs on your device, listening for requests on port `8080`. A Python Flask app runs on `localhost:5000` to serve the control panel.
2.  **Nginx Virtual Hosts:** The `nginx.conf` file is configured with multiple `server` blocks. Nginx directs traffic for `dot.tux` to the Flask app, and traffic for all other `.tux` domains to their corresponding static file directories.
3.  **Dot-Tux Control Panel:** The Flask app provides a web interface that can read, write, and safely modify the `nginx.conf` file. When you add a domain, the app creates a new directory, generates a new `server` block, and triggers a script to safely reload Nginx.
4.  **Local DNS Resolution:** To access these sites, other devices on the same Wi-Fi network must have their `hosts` file edited to point the `.tux` domains to the IP address of the Termux device.

## 🚀 Getting Started

Follow these steps to get Dot-Tux up and running.

### Prerequisites

-   [Termux](https://f-droid.org/en/packages/com.termux/) installed on your Android device.
-   [Termux:Boot](https://f-droid.org/en/packages/com.termux.boot/) installed from F-Droid for auto-start functionality.
-   Your Android device and client computer must be on the **same Wi-Fi network**.
-   Battery optimization **must be disabled** for both Termux and Termux:Boot apps in your phone's settings.

### 1. Server Installation (on Termux)

```bash
# Update packages and install git
pkg update && pkg upgrade -y
pkg install git -y

# Clone the repository
git clone [https://github.com/SullyGreene/Dot-Tux.git](https://github.com/SullyGreene/Dot-Tux.git)

# Navigate into the project directory
cd Dot-Tux

# Make the installer executable
chmod +x install.sh

# Run the installer script. This will set up everything.
./install.sh
````

The installer will guide you through the process and give you the IP address of your device at the end.

### 2\. Client Configuration (on your Computer)

To access your `.tux` domains, you need to tell your computer where to find them.

1.  **Find your Termux device's local IP address.** If you missed it during installation, run `ifconfig` in Termux and look for the `inet` address under the `wlan0` interface (e.g., `192.168.1.42`).

2.  **Edit your `hosts` file** with administrator/sudo privileges.

      - **Windows:** `C:\Windows\System32\drivers\etc\hosts`
      - **macOS / Linux:** `/etc/hosts`

3.  **Add an entry** for the control panel. Replace `YOUR_TERMUX_IP` with the IP you just found.

    ```
    # Dot-Tux Server
    YOUR_TERMUX_IP   dot.tux
    ```

    *You will need to add new lines here for every domain you create later (e.g., `YOUR_TERMUX_IP flipper.tux`).*

### 3\. Access Your Control Panel

Open a web browser on your computer and navigate to:

**`http://dot.tux:8080`**

You should now see the Dot-Tux control panel, ready to manage your domains\!

## 🛠️ Server Management Scripts

Inside the `Dot-Tux` directory in Termux, you can use these scripts to control the server manually:

  - `./start.sh`: Starts the Nginx and Python services.
  - `./stop.sh`: Stops all related services and releases the wakelock.
  - `./reload.sh`: Safely tests and reloads the Nginx configuration (used internally by the app).

## 🤝 Contributing

Contributions are welcome\! If you have an idea for a new feature or have found a bug, please open an issue or submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📜 License

This project is distributed under the MIT License. See `LICENSE.txt` for more information.

```
```
