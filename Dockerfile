FROM cloudron/base:4.0.0@sha256:31b195ed0662bdb06a6e8a5ddbedb6f191ce92e8bee04c03fb02dd4e9d0286df

ENV PYTHONUNBUFFERED 1
ENV VENV_PATH="/app/code/.venv"

RUN mkdir -p /app/code/bikeWeite /app/pkg ${VENV_PATH}

WORKDIR /app/code/bikeWeite

ARG VERSION=deployment-ready

RUN wget https://github.com/AnjaWurli/bikeWeiter/archive/refs/heads/${VERSION}.tar.gz -O - | \
    tar -xz --strip-components 1 -C /app/code/bikeWeite

ENV PYTHONPATH=/app/code/bikeWeite:/app/data/bikeWeite

RUN virtualenv -p /usr/bin/python3.10 ${VENV_PATH}
ENV PATH=${VENV_PATH}/bin:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends musl-dev libwebp-dev cargo libldap-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN source ${VENV_PATH}/bin/activate && \
    ${VENV_PATH}/bin/python -m pip install --upgrade pip pipenv && \
    ${VENV_PATH}/bin/pipenv install --categories=packages,allauth,deploy,postgres --extra-pip-args='--no-cache-dir'


# build frontend
WORKDIR /app/code/bikeWeite
RUN npm install

RUN npm run build
# end of frontend build

WORKDIR /app/code/bikeWeite
RUN python manage.py collectstatic --no-input && \
    ln -sf /run/bikeWeite/.env /app/code/bikeWeite/.env

RUN chown -R cloudron:cloudron /app/code

RUN rm -rf /var/log/nginx && ln -s /run/nginx /var/log/nginx

COPY config/supervisor/* /etc/supervisor/conf.d/
RUN ln -sf /run/bikeWeite/supervisord.log /var/log/supervisor/supervisord.log

COPY start.sh nginx.conf /app/pkg/

RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
