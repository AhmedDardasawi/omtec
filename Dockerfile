FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies
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
    sudo \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && wget -O /tmp/wkhtmltox.deb "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb" \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/*

# Install click 8.1.7 and then frappe-bench
RUN pip3 install click==8.1.7
RUN pip3 install frappe-bench==5.22.8

# Create a non-root user and set up directories
RUN useradd -m -s /bin/bash frappe
RUN mkdir -p /home/frappe/bench && chown -R frappe:frappe /home/frappe

# Switch to frappe user
USER frappe
WORKDIR /home/frappe/bench

# Initialize bench
RUN bench init frappe-bench --python python3 --skip-assets

WORKDIR /home/frappe/bench/frappe-bench

# Install ERPNext
RUN bench get-app erpnext https://github.com/frappe/erpnext --branch version-14

# Switch back to root for startup script
USER root

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash

# Set environment variables
export DB_HOST=${DB_HOST:-localhost}
export DB_PORT=${DB_PORT:-3306}
export DB_USER=${DB_USER:-root}
export DB_PASSWORD=${DB_PASSWORD:-}
export SITE_NAME=${SITE_NAME:-erp.example.com}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}

cd /home/frappe/bench/frappe-bench

# Wait for database
echo "Waiting for database..."
while ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -P $DB_PORT -e "SELECT 1;" > /dev/null 2>&1; do
  sleep 5
done

# Check if site exists
if [ ! -f sites/.initialized ]; then
  echo "Creating site: $SITE_NAME"
  sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench new-site $SITE_NAME --mariadb-root-password=$DB_PASSWORD --admin-password=$ADMIN_PASSWORD --force"
  sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench --site $SITE_NAME install-app erpnext"
  touch sites/.initialized
  echo "Site created successfully!"
fi

echo "Starting ERPNext..."
sudo -u frappe bash -c "cd /home/frappe/bench/frappe-bench && bench start"
EOF

RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]
