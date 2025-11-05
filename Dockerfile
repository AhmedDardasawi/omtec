FROM frappe/erpnext:version-14

# Create startup script for Railway
RUN printf '#!/bin/bash\n\
\n\
# Wait for database\n\
echo "Waiting for database..."\n\
while ! mysql -h $DB_HOST -u root -p$DB_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; do\n\
  echo "Database not ready, waiting..."\n\
  sleep 5\n\
done\n\
\n\
# Check if site exists, if not create it\n\
if [ ! -f /home/frappe/frappe-bench/sites/.initialized ]; then\n\
  echo "Creating new site..."\n\
  cd /home/frappe/frappe-bench\n\
  bench new-site $SITE_NAME \\\n\
    --mariadb-root-password=$DB_PASSWORD \\\n\
    --admin-password=$ADMIN_PASSWORD \\\n\
    --install-app erpnext \\\n\
    --force\n\
  touch /home/frappe/frappe-bench/sites/.initialized\n\
  echo "Site created successfully!"\n\
fi\n\
\n\
# Start the application\n\
echo "Starting ERPNext..."\n\
cd /home/frappe/frappe-bench\n\
bench start\n' > /start.sh

RUN chmod +x /start.sh

EXPOSE 8000

CMD ["/bin/bash", "/start.sh"]
