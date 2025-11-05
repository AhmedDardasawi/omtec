FROM frappe/erpnext:version-14

EXPOSE 8000

# Create startup script
RUN printf '#!/bin/bash\n\
\n\
echo "=== Starting ERPNext on Railway === "\n\
echo "Site: $SITE_NAME"\n\
echo "Database: $DB_HOST:$DB_PORT"\n\
\n\
# Wait for database connection\n\
echo "Waiting for database..."\n\
for i in {1..30}; do\n\
  if mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "SELECT 1;" &>/dev/null; then\n\
    echo "✓ Database connection successful"\n\
    break\n\
  fi\n\
  echo "Attempt $i/30: Database not ready, waiting 5 seconds..."\n\
  sleep 5\n\
done\n\
\n\
cd /home/frappe/frappe-bench\n\
\n\
# Check if site exists, if not create it\n\
if bench list-sites | grep -q "$SITE_NAME"; then\n\
  echo "✓ Site $SITE_NAME already exists"\n\
else\n\
  echo "Creating new site: $SITE_NAME"\n\
  bench new-site $SITE_NAME \\\n\
    --db-host $DB_HOST \\\n\
    --db-port $DB_PORT \\\n\
    --mariadb-root-username $DB_USER \\\n\
    --mariadb-root-password $DB_PASSWORD \\\n\
    --admin-password $ADMIN_PASSWORD \\\n\
    --install-app erpnext \\\n\
    --force\n\
  echo "✓ Site created and ERPNext installed"\n\
fi\n\
\n\
echo "Starting ERPNext server..."\n\
bench start\n' > /home/frappe/start.sh

RUN chmod +x /home/frappe/start.sh

CMD ["/bin/bash", "/home/frappe/start.sh"]
