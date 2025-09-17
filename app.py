import os
import subprocess
import re
import shutil
from flask import Flask, render_template_string, request, redirect, url_for, flash

# ==============================================================================
# Dot-Tux Control Panel
#
# A Flask web application to dynamically manage Nginx server blocks for
# local domain hosting within Termux.
# ==============================================================================


# --- Configuration Constants ---
# Use environment variables for robust path handling in Termux
HOME_DIR = os.getenv("HOME")
SITES_DIR = os.path.join(HOME_DIR, "sites")
NGINX_CONF_PATH = os.path.join(os.getenv("PREFIX", ""), "etc", "nginx", "nginx.conf")
RELOAD_SCRIPT_PATH = os.path.join(HOME_DIR, "Dot-Tux", "reload.sh")
CONTROL_PANEL_DOMAIN = "dot.tux"

# --- Flask App Initialization ---
app = Flask(__name__)
# A secret key is required for flashing messages to the user
app.secret_key = os.urandom(24)


# --- Nginx & Filesystem Helper Functions ---

def get_managed_domains():
    """
    Parses the nginx.conf file to find all domains managed by Dot-Tux,
    identifiable by special comment markers.
    """
    domains = []
    try:
        with open(NGINX_CONF_PATH, 'r') as f:
            content = f.read()
            # Regex to find domains within our specific comment markers
            # Example: # START dot-tux domain: example.tux
            found = re.findall(r'# START dot-tux domain: (.*)', content)
            domains = [d for d in found if d != CONTROL_PANEL_DOMAIN]
    except FileNotFoundError:
        flash("CRITICAL: Nginx config file not found!", "danger")
    return sorted(domains)


def add_domain_config(domain):
    """
    Appends a new, properly formatted Nginx server block for the given
    domain to the configuration file, wrapped in management comments.
    """
    site_path = os.path.join(SITES_DIR, domain)
    
    # 1. Create the directory for the new site's files
    os.makedirs(site_path, exist_ok=True)
    
    # 2. Create a default index.html for the new site
    with open(os.path.join(site_path, "index.html"), "w") as f:
        f.write(f"<h1>Welcome to {domain}</h1>\n<p>This site is managed by Dot-Tux.</p>")

    # 3. Define the Nginx server block template
    new_server_block = f"""
# START dot-tux domain: {domain}
server {{
    listen 8080;
    server_name {domain};

    location / {{
        root {site_path};
        index index.html index.htm;
    }}
}}
# END dot-tux domain: {domain}
"""
    # 4. Append the new block to the main config file
    with open(NGINX_CONF_PATH, 'a') as f:
        f.write(new_server_block)
    return True


def remove_domain_config(domain):
    """
    Safely removes a domain's server block from the nginx.conf file by
    locating its management comment markers and excluding the content between them.
    It also removes the associated site directory.
    """
    lines_to_keep = []
    in_block_to_delete = False
    
    start_marker = f"# START dot-tux domain: {domain}"
    end_marker = f"# END dot-tux domain: {domain}"

    try:
        # 1. Filter the nginx.conf content
        with open(NGINX_CONF_PATH, 'r') as f:
            for line in f:
                if start_marker in line:
                    in_block_to_delete = True
                
                if not in_block_to_delete:
                    lines_to_keep.append(line)
                
                if end_marker in line:
                    in_block_to_delete = False

        # 2. Overwrite the config file with the filtered content
        with open(NGINX_CONF_PATH, 'w') as f:
            f.writelines(lines_to_keep)

        # 3. Remove the site's directory
        site_path = os.path.join(SITES_DIR, domain)
        if os.path.isdir(site_path):
            shutil.rmtree(site_path)
            
        return True
    except Exception as e:
        flash(f"Error during domain removal: {e}", "danger")
        return False


def run_reload_script():
    """
    Executes the reload.sh script to test and apply the new Nginx config.
    Returns True on success, False on failure.
    """
    try:
        # We use subprocess.run to wait for the script to complete
        result = subprocess.run(['bash', RELOAD_SCRIPT_PATH], capture_output=True, text=True)
        if result.returncode == 0:
            flash("Nginx reloaded successfully.", "success")
            return True
        else:
            # If the reload script fails, flash the error output
            flash(f"Nginx reload failed! Config may be broken. Error: {result.stdout}{result.stderr}", "danger")
            return False
    except FileNotFoundError:
        flash("CRITICAL: reload.sh script not found!", "danger")
        return False


# --- HTML & CSS Template ---

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-ag-UTF-8">
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
    </style>
</head>
<body class="font-sans antialiased">
    <div class="container mx-auto p-4 md:p-8 max-w-3xl">
        
        <header class="text-center mb-8">
            <h1 class="text-4xl font-bold text-white">🐧 Dot-Tux</h1>
            <p class="text-lg text-gray-400">Termux Local Domain Manager</p>
        </header>

        <!-- Flash Messages -->
        {% with messages = get_flashed_messages(with_categories=true) %}
          {% if messages %}
            <div class="mb-4">
            {% for category, message in messages %}
              <div class="p-4 rounded-lg text-white {{ 'bg-green-600' if category == 'success' else 'bg-red-600' }}">
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
                        <a href="http://{{ domain }}:8080" target="_blank" class="text-blue-400 hover:underline font-mono">
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
    """
    Renders the main dashboard page, displaying existing domains.
    """
    domains = get_managed_domains()
    return render_template_string(HTML_TEMPLATE, domains=domains)


@app.route('/add', methods=['POST'])
def add_domain():
    """
    Handles the form submission for adding a new domain.
    """
    domain_prefix = request.form.get('domain', '').strip().lower()
    
    # Basic validation
    if not domain_prefix or not re.match(r'^[a-z0-9-]+$', domain_prefix):
        flash("Invalid domain name. Use only letters, numbers, and hyphens.", "danger")
        return redirect(url_for('index'))
        
    full_domain = f"{domain_prefix}.tux"
    
    if full_domain in get_managed_domains() or full_domain == CONTROL_PANEL_DOMAIN:
        flash(f"Domain '{full_domain}' already exists.", "danger")
        return redirect(url_for('index'))
    
    # Add config and reload Nginx
    if add_domain_config(full_domain):
        run_reload_script()
    else:
        flash("Failed to create domain configuration.", "danger")
        
    return redirect(url_for('index'))


@app.route('/delete/<domain>', methods=['POST'])
def delete_domain(domain):
    """
    Handles the request to delete a domain.
    """
    # Security check: do not allow deleting the control panel domain
    if domain == CONTROL_PANEL_DOMAIN:
        flash("Cannot delete the control panel domain.", "danger")
        return redirect(url_for('index'))
    
    if domain not in get_managed_domains():
        flash(f"Domain '{domain}' not found.", "danger")
        return redirect(url_for('index'))
        
    # Remove config and reload Nginx
    if remove_domain_config(domain):
        run_reload_script()
    else:
        flash(f"Failed to remove domain '{domain}'.", "danger")

    return redirect(url_for('index'))


# --- Main Execution ---

if __name__ == '__main__':
    # The app should listen on 127.0.0.1 (localhost) on a dedicated port.
    # Nginx will be configured to proxy requests for dot.tux to this server.
    # This keeps the control panel secure and accessible via the main port 8080.
    # NOTE: The default nginx.conf in your repo MUST have the proxy_pass rule for dot.tux.
    app.run(host='127.0.0.1', port=5000)
