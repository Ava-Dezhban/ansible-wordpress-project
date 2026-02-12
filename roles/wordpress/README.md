# Project Overview

I created a **Bash script** to set up the project structure, roles, tasks, templates, and default variables for the WordPress role. After running the script, the project structure is ready, and all necessary files are generated automatically.

The script includes:

- `site.yml` — Main playbook that deploys WordPress.  
- `inventory` — Hosts file for target server. (I just have one server)  
- `roles/wordpress` — Role containing tasks, handlers, templates, defaults, and metadata.


## How I Tested the Project

I executed the following steps to test the project:

1. **Generate project structure & files** using the script:
./setup_project.sh

2. **Deploy WordPress to the target server**
ansible-playbook -i inventory site.yml -K


## Verify the setup on the target server:

1. **Check that Apache service is running**
sudo systemctl status apache2

2. **Check that WordPress files exist in the document root**
ls -l /var/www/html/wordpress

3. **Test the site in a browser at**
http://192.168.80.130/ or,
curl -I http://localhost

I put all the needed outputS on the output folder :)
