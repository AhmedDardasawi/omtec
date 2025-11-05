#!/bin/bash

# Wait for database
echo "Waiting for database..."
while ! mysql -h $DB_HOST -u root -p$DB_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; do
  echo "Database not ready, waiting..."
  sleep 5
done

# Check if site exists, if not create it
if [ ! -f /home/frappe/frappe-bench/sites/.initialized ]; then
  echo "Creating new site..."
  cd /home/frappe/frappe-bench
  bench new-site $SITE_NAME \
    --mariadb-root-password=$DB_PASSWORD \
    --admin-password=$ADMIN_PASSWORD \
    --install-app erpnext \
    --force
  touch /home/frappe/frappe-bench/sites/.initialized
  echo "Site created successfully!"
fi

# Start the application
echo "Starting ERPNext..."
cd /home/frappe/frappe-bench
bench start
