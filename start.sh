#!/bin/bash

set -e

echo "Starting ERPNext Setup..."

cd /home/frappe/bench/frappe-bench

# تعيين متغيرات البيئة
export DB_HOST=${DB_HOST:-localhost}
export DB_PORT=${DB_PORT:-3306}
export DB_USER=${DB_USER:-root}
export DB_PASSWORD=${DB_PASSWORD:-}
export SITE_NAME=${SITE_NAME:-erp.example.com}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
export INSTALL_APPS=${INSTALL_APPS:-erpnext}

# انتظار اتصال قاعدة البيانات
echo "Waiting for database at $DB_HOST:$DB_PORT..."
while ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -P $DB_PORT -e "SELECT 1;" > /dev/null 2>&1; do
    echo "Retrying database connection in 5 seconds..."
    sleep 5
done
echo "Database connection established!"

# التحقق مما إذا كان الموقع موجودًا بالفعل
if [ ! -f "sites/.initialized" ]; then
    echo "Creating new site: $SITE_NAME"
    
    # إنشاء موقع جديد
    sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench new-site $SITE_NAME \
        --mariadb-root-password=$DB_PASSWORD \
        --admin-password=$ADMIN_PASSWORD \
        --force"
    
    # تثبيت تطبيقات إضافية
    if [ ! -z "$INSTALL_APPS" ]; then
        for app in $INSTALL_APPS; do
            echo "Installing app: $app"
            sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench --site $SITE_NAME install-app $app"
        done
    fi
    
    # وضع علامة على التهيئة
    touch sites/.initialized
    echo "Site $SITE_NAME created successfully!"
else
    echo "Site already initialized, skipping creation..."
fi

echo "Starting bench services..."
sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench start"