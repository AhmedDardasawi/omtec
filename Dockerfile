FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    NODE_ENV=production

# تثبيت dependencies الأساسية
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

# تثبيت Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# تثبيت dependencies إضافية
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

# تثبيت wkhtmltopdf
RUN wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install -y /tmp/wkhtmltox.deb \
    && rm /tmp/wkhtmltox.deb

# إنشاء مستخدم frappe
RUN useradd -m -s /bin/bash frappe

# تثبيت bench
RUN pip3 install frappe-bench

# إنشاء مجلد العمل
RUN mkdir -p /home/frappe/bench && chown -R frappe:frappe /home/frappe

# التبديل إلى مستخدم frappe
USER frappe
WORKDIR /home/frappe/bench

# تهيئة bench
RUN bench init frappe-bench --python python3 --skip-assets

WORKDIR /home/frappe/bench/frappe-bench

# تثبيت ERPNext
RUN bench get-app erpnext https://github.com/frappe/erpnext --branch version-14

# العودة إلى root لإنشاء سكريبت التشغيل
USER root

# نسخ سكريبت التشغيل
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000 9000

CMD ["/bin/bash", "/start.sh"]