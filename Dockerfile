FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    NODE_ENV=production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    python3-venv \
    software-properties-common \
    gnupg \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    mariadb-client \
    libmariadb-dev \
    build-essential \
    python3-dev \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb

# Create frappe user
RUN useradd -m -s /bin/bash frappe

# Install bench with specific version for compatibility
RUN pip3 install frappe-bench==5.15.3

# Create app directory
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

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]
