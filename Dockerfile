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

# Create a non-root user
RUN useradd -m -s /bin/bash frappe
USER frappe
WORKDIR /home/frappe

# Install bench for the user
RUN pip3 install --user frappe-bench

# Add user's local bin to PATH
ENV PATH="/home/frappe/.local/bin:${PATH}"

# Initialize bench as the user
RUN bench init frappe-bench --python python3 --skip-assets

WORKDIR /home/frappe/frappe-bench

# Install ERPNext
RUN bench get-app erpnext https://github.com/frappe/erpnext --branch version-14

# Switch back to root for the startup script (if needed, but we'll adjust the startup script to run as frappe)
USER root

# Create startup script that runs as the frappe user
RUN printf '#!/bin/bash\n\
sudo -u frappe bash -c "cd /home/frappe/frappe-bench && bench start"\n' > /start.sh

RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]
