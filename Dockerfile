FROM frappe/erpnext:version-14

USER root

# Create startup script in a writable location
RUN printf '#!/bin/bash\n\necho "Waiting for database..."\nwhile ! mysql -h $DB_HOST -u root -p$DB_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; do\n  echo "Database not ready, waiting..."\n  sleep 5\ndone\n\nif [ ! -f /home/frappe/frappe-bench/sites/.initialized ]; then\n  echo "Creating new site..."\n  cd /home/frappe/frappe-bench\n  bench new-site $SITE_NAME \\\n    --mariadb-root-password=$DB_PASSWORD \\\n    --admin-password=$ADMIN_PASSWORD \\\n    --install-app erpnext \\\n    --force\n  touch /home/frappe/frappe-bench/sites/.initialized\n  echo "Site created successfully!"\nfi\n\necho "Starting ERPNext..."\ncd /home/frappe/frappe-bench\nbench start\n' > /home/frappe/start.sh

RUN chmod +x /home/frappe/start.sh

USER frappe

EXPOSE 8000

CMD ["/bin/bash", "/home/frappe/start.sh"]
