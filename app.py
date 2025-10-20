import os
import subprocess
import re
import shutil
from flask import Flask, render_template_string, request, redirect, url_for, flash

# ==============================================================================
# Dot-Tux Control Panel (Fully Upgraded & Modular)
#
# This Flask app now intelligently detects the chosen web server (Nginx, Caddy,
# or Lighttpd) and manages site configurations in a modular, file-based way.
# ==============================================================================


# --- Configuration Constants ---
HOME_DIR = os.getenv("HOME")
PREFIX_DIR = os.getenv("PREFIX", "")
SITES_DIR = os.path.join(HOME_DIR, "sites")
SITES_ENABLED_DIR = os.path.join(PREFIX_DIR, "etc", "dottux", "sites-enabled")
CHOICE_FILE = os.path.join(HOME_DIR, ".dottux_choice")
CONTROL_PANEL_DOMAIN = "dot.tux"

# --- Flask App Initialization ---
app = Flask(__name__)
app.secret_key = os.urandom(24)


# --- Server & Filesystem Helper Functions ---

def get_server_choice():
    """Reads the server choice file to determine the active web server."""
    try:
        with open(CHOICE_FILE, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return None

def get_managed_domains():
    """
    Scans the sites-enabled directory to find all managed domains.
    This is now server-agnostic.
    """
    domains = []
    if not os.path.isdir(SITES_ENABLED_DIR):
        flash("CRITICAL: Sites-enabled directory not found!", "danger")
        return []
    
    for filename in os.listdir(SITES_ENABLED_DIR):
        # We identify domains by their config file names
        if filename.endswith(('.conf', '.tux')):
             # Remove extension for display
            domain = filename.replace('.conf', '').replace('.tux', '')
            if domain != CONTROL_PANEL_DOMAIN:
                domains.append(domain)
    return sorted(domains)

def add_domain_config(domain, server_choice):
    """
    Creates a new server configuration file for the chosen server,
    plus the site directory and a default index.html.
    """
    site_path = os.path.join(SITES_DIR, domain)
    os.makedirs(site_path, exist_ok=True)
    
    # Create a default index.html
    with open(os.path.join(site_path, "index.html"), "w") as f:
        f.write(f"<h1>Welcome to {domain}</h1>\n<p>This site is managed by Dot-Tux.</p>")

    config_content = ""
    config_filename = f"{domain}.conf"

    # Generate the appropriate config block for the selected server
    if server_choice == 'nginx':
        config_content = f"""
server {{
    listen 80;
    server_name {domain};
    root {site_path};
    index index.html index.htm;
}}
"""
    elif server_choice == 'caddy':
        config_filename = domain # Caddy doesn't need an extension
        config_content = f"""
{domain}:80 {{
    root * {site_path}
    file_server
}}
"""
    elif server_choice == 'lighttpd':
        config_content = f"""
\$HTTP["host"] == "{domain}" {{
    server.document-root = "{site_path}"
}}
"""
    else:
        flash(f"Unknown server type '{server_choice}'!", "danger")
        return False

    # Write the new configuration file
    with open(os.path.join(SITES_ENABLED_DIR, config_filename), 'w') as f:
        f.write(config_content)
    return True

def remove_domain_config(domain, server_choice):
    """
    Removes a domain's configuration file and its site directory.
    """
    try:
        # Determine the config filename to delete
        if server_choice == 'caddy':
             config_filename = domain
        else:
             config_filename = f"{domain}.conf"

        config_path = os.path.join(SITES_ENABLED_DIR, config_filename)
        if os.path.exists(config_path):
            os.remove(config_path)

        # Remove the site's directory
        site_path = os.path.join(SITES_DIR, domain)
        if os.path.isdir(site_path):
            shutil.rmtree(site_path)
            
        return True
    except Exception as e:
        flash(f"Error during domain removal: {e}", "danger")
        return False

def run_reload_script():
    """
    Executes the main start.sh script to reload/restart the server.
    This is the safest way to ensure the server comes back online correctly.
    """
    try:
        # We simply call the main start script, which is idempotent and handles
        # reloading or restarting services as needed.
        start_script_path = os.path.join(HOME_DIR, "Dot-Tux", "start.sh")
        result = subprocess.run(['bash', start_script_path], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            flash("Server reloaded and services restarted successfully.", "success")
            return True
        else:
            flash(f"Server reload failed! Error: {result.stdout}{result.stderr}", "danger")
            return False
    except FileNotFoundError:
        flash("CRITICAL: start.sh script not found!", "danger")
        return False
    except subprocess.TimeoutExpired:
        flash("Server reload timed out. Please check the server status manually.", "warning")
        return False

# --- HTML & CSS Template ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dot-Tux Control Panel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background-color: #1a202c; color: #e2e8f0; }
        .card { background-color: #2d3748; }
        .btn-primary { background-color: #4299e1; }
        .btn-primary:hover { background-color: #2b6cb0; }
        .btn-danger { background-color: #e53e3e; }
        .btn-danger:hover { background-color: #c53030; }
        .input-field { background-color: #4a5568; border-color: #718096; }
        .alert-success { background-color: #2f855a; }
        .alert-danger { background-color: #c53030; }
        .alert-warning { background-color: #dd6b20; }
    </style>
</head>
<body class="font-sans antialiased">
    <div class="container mx-auto p-4 md:p-8 max-w-3xl">
        
        <header class="text-center mb-8">
            <h1 class="text-4xl font-bold text-white">🐧 Dot-Tux</h1>
            <p class="text-lg text-gray-400">Termux Local Domain Manager</p>
            <p class="text-sm text-gray-500 mt-1">Managing: <span class="font-mono p-1 bg-gray-700 rounded">{{ server_type | capitalize }}</span></p>
        </header>

        <!-- Flash Messages -->
        {% with messages = get_flashed_messages(with_categories=true) %}
          {% if messages %}
            <div class="mb-4 space-y-2">
            {% for category, message in messages %}
              <div class="p-4 rounded-lg text-white font-semibold alert-{{ category }}">
                {{ message }}
              </div>
            {% endfor %}
            </div>
          {% endif %}
        {% endwith %}

        <!-- Add New Domain Card -->
        <div class="card p-6 rounded-lg shadow-lg mb-8">
            <h2 class="text-2xl font-semibold mb-4 text-white">Add New Domain</h2>
            <form action="{{ url_for('add_domain') }}" method="POST" class="flex flex-col sm:flex-row gap-3">
                <input type="text" name="domain" placeholder="e.g., project-name" required 
                       class="input-field flex-grow p-3 rounded-md border text-white focus:outline-none focus:ring-2 focus:ring-blue-500">
                <button type="submit" class="btn-primary text-white font-bold py-3 px-6 rounded-md transition duration-300">
                    Add .tux Domain
                </button>
            </form>
        </div>

        <!-- Managed Domains List -->
        <div class="card p-6 rounded-lg shadow-lg">
            <h2 class="text-2xl font-semibold mb-4 text-white">Managed Domains</h2>
            {% if domains %}
                <ul class="space-y-3">
                    {% for domain in domains %}
                    <li class="flex items-center justify-between p-3 bg-gray-700 rounded-md">
                        <a href="http://{{ domain }}" target="_blank" class="text-blue-400 hover:underline font-mono">
                            {{ domain }}
                        </a>
                        <form action="{{ url_for('delete_domain', domain=domain) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete {{ domain }}? This cannot be undone.');">
                            <button type="submit" class="btn-danger text-white font-bold py-1 px-3 text-sm rounded-md transition duration-300">
                                Delete
                            </button>
                        </form>
                    </li>
                    {% endfor %}
                </ul>
            {% else %}
                <p class="text-gray-400">No domains have been added yet.</p>
            {% endif %}
        </div>
    </div>
</body>
</html>
"""

# --- Flask Routes ---

@app.route('/')
def index():
    """Renders the main dashboard page."""
    server_choice = get_server_choice()
    if not server_choice:
        flash("Server configuration is missing. Please run the main installer.", "danger")
    
    domains = get_managed_domains()
    return render_template_string(HTML_TEMPLATE, domains=domains, server_type=server_choice or "Unknown")

@app.route('/add', methods=['POST'])
def add_domain():
    """Handles the form submission for adding a new domain."""
    server_choice = get_server_choice()
    if not server_choice:
        flash("Cannot add domain: server choice is not configured.", "danger")
        return redirect(url_for('index'))

    domain_prefix = request.form.get('domain', '').strip().lower()
    
    if not domain_prefix or not re.match(r'^[a-z0-9-]+$', domain_prefix):
        flash("Invalid domain name. Use only letters, numbers, and hyphens.", "danger")
        return redirect(url_for('index'))
        
    full_domain = f"{domain_prefix}.tux"
    
    if full_domain in get_managed_domains() or full_domain == CONTROL_PANEL_DOMAIN:
        flash(f"Domain '{full_domain}' already exists.", "danger")
        return redirect(url_for('index'))
    
    if add_domain_config(full_domain, server_choice):
        run_reload_script()
    else:
        flash("Failed to create domain configuration.", "danger")
        
    return redirect(url_for('index'))

@app.route('/delete/<domain>', methods=['POST'])
def delete_domain(domain):
    """Handles the request to delete a domain."""
    server_choice = get_server_choice()
    if not server_choice:
        flash("Cannot delete domain: server choice is not configured.", "danger")
        return redirect(url_for('index'))

    if domain == CONTROL_PANEL_DOMAIN:
        flash("Cannot delete the control panel domain.", "danger")
        return redirect(url_for('index'))
    
    if domain not in get_managed_domains():
        flash(f"Domain '{domain}' not found.", "danger")
        return redirect(url_for('index'))
        
    if remove_domain_config(domain, server_choice):
        run_reload_script()
    else:
        flash(f"Failed to remove domain '{domain}'.", "danger")

    return redirect(url_for('index'))


# --- Main Execution ---
if __name__ == '__main__':
    # Listens on 127.0.0.1:5000. Nginx/Caddy/Lighttpd should be configured
    # to proxy requests for dot.tux to this address.
    app.run(host='127.0.0.1', port=5000, debug=False)
