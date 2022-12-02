# build custom micro services
FROM satosa AS custom_code
COPY --chown=satosa:satosa src /home/satosa/src
RUN cd /home/satosa/src/static_content; pip install --user .

FROM satosa
COPY *.yaml /etc/satosa/
COPY plugins /etc/satosa/plugins
COPY --from=custom_code /home/satosa/.local /home/satosa/.local
COPY --chown=root:root delayed-entrypoint.sh /usr/local/bin/
ENV STARTUP_DELAY=300
ENTRYPOINT ["delayed-entrypoint.sh"]
CMD ["gunicorn","-b0.0.0.0:8080","satosa.wsgi:app"]
