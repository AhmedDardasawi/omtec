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
    libfreetype6-dev \
    sudo \
    && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && wget -O /tmp/wkhtmltox.deb "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb" \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/*

# Install compatible versions
RUN pip3 install \
    click==8.1.7 \
    requests==2.31.0 \
    jinja2==3.1.2 \
    honcho==1.1.0 \
    semantic-version==2.10.0

# Install available version of frappe-bench
RUN pip3 install frappe-bench==5.22.8

# Create app directory
WORKDIR /opt

# Initialize bench
RUN bench init frappe-bench --python python3 --skip-assets

WORKDIR /opt/frappe-bench

# Install ERPNext
RUN bench get-app erpnext https://github.com/frappe/erpnext --branch version-14

# Create startup script
RUN printf '#!/bin/bash\n\
cd /opt/frappe-bench\n\
\n\
# Wait for database\n\
echo "Waiting for database..."\n\
while ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -P $DB_PORT -e "SELECT 1;" > /dev/null 2>&1; do\n\
  sleep 5\n\
done\n\
\n\
# Create site if not exists\n\
if [ ! -f sites/.initialized ]; then\n\
  echo "Creating site: $SITE_NAME"\n\
  bench new-site $SITE_NAME \\\n\
    --mariadb-root-password=$DB_PASSWORD \\\n\
    --admin-password=$ADMIN_PASSWORD \\\n\
    --force\n\
  bench --site $SITE_NAME install-app erpnext\n\
  touch sites/.initialized\n\
  echo "Site created successfully!"\n\
fi\n\
\n\
echo "Starting ERPNext..."\n\
bench start\n' > /start.sh

RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]
