FROM cloudron/base:4.0.0@sha256:31b195ed0662bdb06a6e8a5ddbedb6f191ce92e8bee04c03fb02dd4e9d0286df

ENV PYTHONUNBUFFERED 1
ENV VENV_PATH="/app/code/.venv"

RUN mkdir -p /app/code/djac /app/pkg ${VENV_PATH}

WORKDIR /app/code/djac

ADD django /app/code/djac

RUN virtualenv -p /usr/bin/python3.10 ${VENV_PATH}
ENV PATH=${VENV_PATH}/bin:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends musl-dev libwebp-dev cargo libldap-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN source ${VENV_PATH}/bin/activate && \
    ${VENV_PATH}/bin/python -m pip install --upgrade pip pipenv && \
    ${VENV_PATH}/bin/pipenv install --deploy

RUN python manage.py collectstatic --no-input && \
    ln -sf /run/djac/.env /app/code/djac/.env

RUN chown -R cloudron:cloudron /app/code

RUN rm -rf /var/log/nginx && ln -s /run/nginx /var/log/nginx

COPY config/supervisor/* /etc/supervisor/conf.d/
RUN ln -sf /run/djac/supervisord.log /var/log/supervisor/supervisord.log

COPY start.sh nginx.conf /app/pkg/

RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
