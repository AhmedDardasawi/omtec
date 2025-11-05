RUN pip3 install \
    click==8.1.7 \
    semantic-version==2.10.0 \
    uv==0.7.22 \
    gitpython==3.1.45 \
    requests==2.32.4 \
    jinja2==3.1.6

RUN pip3 install --no-deps frappe-bench
