FROM frappe/erpnext:v16

USER root

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER frappe

WORKDIR /home/frappe/frappe-bench

ARG ERP_NEXT_REPO=https://github.com/Smartbit-Solutions/erpnext.git
ARG BRANCH=rebrand-to-smartbits-erp

RUN git clone --depth 1 --branch ${BRANCH} ${ERP_NEXT_REPO} apps/erpnext_custom && \
    cp -r apps/erpnext_custom/* apps/erpnext/ && \
    rm -rf apps/erpnext_custom

RUN bench build --app erpnext
