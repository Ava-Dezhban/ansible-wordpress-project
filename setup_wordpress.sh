#!/bin/bash

# Setup the structure of project 
PROJECT_ROOT="ansible-wordpress-project"
mkdir -p $PROJECT_ROOT/roles/wordpress/{tasks,handlers,vars,defaults,templates,meta}

# Create Main Playbook
cat <<EOF > $PROJECT_ROOT/site.yml
---
- name: Deploy WordPress Site
  hosts: myservers
  become: yes
  roles:
    - wordpress
EOF

# Create Inventory 
cat <<EOF > $PROJECT_ROOT/inventory
[myservers]
192.168.80.130 ansible_user=ava1 
EOF

# Create defaults/main.yml
cat <<EOF > $PROJECT_ROOT/roles/wordpress/defaults/main.yml
---
db_name: wordpress_db
db_user: wp_admin
db_password: 123
http_port: 8888
server_hostname: localhost
document_root: /var/www/html/wordpress
EOF

# Create tasks/main.yml
cat <<EOF > $PROJECT_ROOT/roles/wordpress/tasks/main.yml
---
- name: Install LAMP stack packages
  apt:
    name:
      - apache2
      - mariadb-server
      - php
      - php-mysql
      - libapache2-mod-php
      - python3-pymysql
    state: present
    update_cache: yes

- name: Start and enable MariaDB service
  service:
    name: mariadb
    state: started
    enabled: yes

- name: Create WordPress Database
  mysql_db:
    name: "{{ db_name }}"
    state: present
    login_unix_socket: /var/run/mysqld/mysqld.sock

- name: Create WordPress Database User
  mysql_user:
    name: "{{ db_user }}"
    password: "{{ db_password }}"
    priv: "{{ db_name }}.*:ALL"
    state: present
    login_unix_socket: /var/run/mysqld/mysqld.sock

- name: Download and extract WordPress
  unarchive:
    src: https://wordpress.org/latest.tar.gz
    dest: /var/www/html
    remote_src: yes
    creates: /var/www/html/wordpress

- name: Configure wp-config.php from template
  template:
    src: wp-config.php.j2
    dest: "{{ document_root }}/wp-config.php"

- name: Set permissions for WordPress directory
  file:
    path: "{{ document_root }}"
    owner: www-data
    group: www-data
    recurse: yes

- name: Setup Apache VirtualHost
  template:
    src: wordpress.conf.j2
    dest: /etc/apache2/sites-available/wordpress.conf
  notify: Restart Apache

- name: Enable WordPress site
  command: a2ensite wordpress.conf
  args:
    creates: /etc/apache2/sites-enabled/wordpress.conf
  notify: Restart Apache
EOF

# Create handlers/main.yml
cat <<EOF > $PROJECT_ROOT/roles/wordpress/handlers/main.yml
---
- name: Restart Apache
  service:
    name: apache2
    state: restarted
EOF

# Create Templates
# Template: wp-config.php.j2
cat <<EOF > $PROJECT_ROOT/roles/wordpress/templates/wp-config.php.j2
<?php
define( 'DB_NAME', '{{ db_name }}' );
define( 'DB_USER', '{{ db_user }}' );
define( 'DB_PASSWORD', '{{ db_password }}' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

# Template: wordpress.conf.j2
cat <<EOF > $PROJECT_ROOT/roles/wordpress/templates/wordpress.conf.j2
<VirtualHost *:{{ http_port }}>
    ServerName {{ server_hostname }}
    DocumentRoot {{ document_root }}
    <Directory {{ document_root }}>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Create README
cat <<EOF > $PROJECT_ROOT/roles/wordpress/README.md
# WordPress Ansible Role
Automated installation of WordPress on LAMP stack.

## Usage
1. Edit \`inventory\`
2. Run: \`ansible-playbook -i inventory site.yml\`
EOF

# Create meta/main.yml
cat <<EOF > $PROJECT_ROOT/roles/wordpress/meta/main.yml
galaxy_info:
  author: AvA
  description: WordPress installation role
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - all
EOF


