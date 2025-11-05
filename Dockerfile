FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies in one RUN command to reduce layers
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    mariadb-client \
    libmariadb-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    sudo \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.focal_amd64.deb \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/*

# Install bench
RUN pip3 install frappe-bench

# Create app directory
WORKDIR /opt

# Initialize bench
RUN bench init frappe-bench --python python3 --skip-assets

WORKDIR /opt/frappe-bench

# Install ERPNext
RUN bench get-app erpnext https://github.com/frappe/erpnext --branch version-14

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash
cd /opt/frappe-bench

# Wait for database
echo "Waiting for database..."
while ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -P $DB_PORT -e "SELECT 1;" > /dev/null 2>&1; do
  sleep 5
done

# Create site if not exists
if [ ! -f sites/.initialized ]; then
  echo "Creating site: $SITE_NAME"
  bench new-site $SITE_NAME \
    --mariadb-root-password=$DB_PASSWORD \
    --admin-password=$ADMIN_PASSWORD \
    --force
  bench --site $SITE_NAME install-app erpnext
  touch sites/.initialized
  echo "Site created successfully!"
fi

echo "Starting ERPNext..."
bench start
EOF

RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]
