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

* **Zero-Cost Hosting:** Run a real web server directly on your Android device.
* **Dynamic Domain Management:** A simple web UI (`dot.tux`) to add/remove Nginx sites on the fly.
* **Automated Setup:** A single `install.sh` script handles all dependencies and configuration.
* **Boots on Start:** Integrates with Termux\:Boot to launch the server automatically when your device starts.
* **Lightweight & Portable:** Built on a minimal stack, requiring very few resources.
* **Safe Reloads:** Includes configuration checks to prevent broken Nginx configs from being loaded.

## ⚙️ How It Works

1. **Termux Server:** An Nginx instance runs on your device, listening for requests on port `8080`. A Python Flask app runs on `localhost:5000` to serve the control panel.
2. **Nginx Virtual Hosts:** The `nginx.conf` file is configured with multiple `server` blocks. Nginx directs traffic for `dot.tux` to the Flask app, and traffic for all other `.tux` domains to their corresponding static file directories.
3. **Dot-Tux Control Panel:** The Flask app provides a web interface that can read, write, and safely modify the `nginx.conf` file. When you add a domain, the app creates a new directory, generates a new `server` block, and triggers a script to safely reload Nginx.
4. **Local DNS Resolution:** To access these sites, other devices on the same Wi-Fi network must have their `hosts` file edited to point the `.tux` domains to the IP address of the Termux device.

## 🚀 Getting Started

Follow these steps to get Dot-Tux up and running.

### Prerequisites

* \[Termux]\([https://f-droid.org/en/pa](https://f-droid.org/en/pa)
