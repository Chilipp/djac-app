FROM cloudron/base:4.0.0@sha256:31b195ed0662bdb06a6e8a5ddbedb6f191ce92e8bee04c03fb02dd4e9d0286df

ARG VERSION=1.4.8
# this will be picked up by asset building and exposed in the UI
ARG BUILD_REF=4378a6b0c78f80d4e0f3b016ba4f4cf7b8ea5705


ENV PYTHONUNBUFFERED 1
ENV VENV_PATH="/app/code/.venv"

RUN mkdir -p /app/code/tandoor /app/pkg ${VENV_PATH}

WORKDIR /app/code/tandoor

RUN wget https://github.com/TandoorRecipes/recipes/archive/refs/tags/${VERSION}.tar.gz -O - | \
    tar -xz --strip-components 1 -C /app/code/tandoor

ENV PYTHONPATH=/app/code/tandoor:/app/data/tandoor

RUN virtualenv -p /usr/bin/python3.10 ${VENV_PATH}
ENV PATH=${VENV_PATH}/bin:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        musl-dev \
        zlib1g-dev \
        libjpeg-dev \
        libwebp-dev \
        cargo \
        libffi-dev \
        libssl-dev \
        libsasl2-dev \
        libldap2-dev \
        libldap-common \
        ldap-utils \
        python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN source ${VENV_PATH}/bin/activate && \
    ${VENV_PATH}/bin/python -m pip install --upgrade pip && \
    ${VENV_PATH}/bin/pip install wheel==0.37.1 && \
    ${VENV_PATH}/bin/pip install setuptools_rust==1.1.2 && \
    ${VENV_PATH}/bin/pip install -r requirements.txt --no-cache-dir

RUN echo "VERSION_NUMBER = \"${VERSION}\"" > /app/code/tandoor/recipes/version.py && \
    echo "BUILD_REF = \"${BUILD_REF}\"" >> /app/code/tandoor/recipes/version.py

# build frontend
WORKDIR /app/code/tandoor/vue
RUN yarn install \
  --prefer-offline \
  --frozen-lockfile \
  --non-interactive \
  --production=false \
  --network-timeout 1000000 # https://github.com/docker/build-push-action/issues/471

RUN yarn build

RUN rm -rf node_modules && \
  NODE_ENV=production yarn install \
  --prefer-offline \
  --pure-lockfile \
  --non-interactive \
  --production=true

RUN rm -rf /usr/local/share/.cache/yarn
# end of frontend build

WORKDIR /app/code/tandoor
RUN mv /app/code/tandoor/cookbook/static /app/pkg/static && \
    ln -sf /run/tandoor/static /app/code/tandoor/cookbook/static && \
    ln -sf /app/data/data/staticfiles /app/code/tandoor/staticfiles && \
    ln -sf /app/data/data/media /app/code/tandoor/media && \
    ln -sf /run/tandoor/.env /app/code/tandoor/.env
#    ln -sf /app/data/data/mediafiles /app/code/tandoor/mediafiles

# fix permissions
RUN chown -R cloudron:cloudron /app/code

# Add nginx config
RUN rm /etc/nginx/sites-enabled/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
#    ln -sf /run/tandoor/tandoor.conf /etc/nginx/sites-enabled/tandoor.conf
#COPY config/nginx/tandoor.conf /app/pkg/tandoor.conf
COPY config/nginx/tandoor.conf /etc/nginx/sites-enabled/tandoor.conf
COPY config/nginx/readonlyrootfs.conf /etc/nginx/conf.d/readonlyrootfs.conf

# Add supervisor configs
COPY config/supervisor/* /etc/supervisor/conf.d/
RUN ln -sf /run/tandoor/supervisord.log /var/log/supervisor/supervisord.log

COPY start.sh /app/pkg/

RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
