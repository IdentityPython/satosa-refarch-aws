FROM satosa AS custom_code
# workaround https://github.com/IdentityPython/satosa-docker/issues/6
USER root
RUN mkdir -p /home/satosa; chown satosa:satosa /home/satosa
USER satosa
# build custom micro services
COPY --chown=satosa:satosa src /home/satosa/src
RUN cd /home/satosa/src/static_content; pip install --user .

FROM satosa
USER root
RUN pip install --no-cache-dir satosa[ldap]==${SATOSA_VERSION}
COPY --chown=satosa:satosa *.yaml /etc/satosa/
COPY --chown=satosa:satosa plugins /etc/satosa/plugins
RUN mkdir -p /home/satosa; chown satosa:satosa /home/satosa
COPY --from=custom_code /home/satosa/.local /home/satosa/.local
COPY delayed-entrypoint.sh /usr/local/bin/
USER satosa:satosa
ENV STARTUP_DELAY=300
ENTRYPOINT ["delayed-entrypoint.sh"]
CMD ["gunicorn","-b0.0.0.0:8080","satosa.wsgi:app"]
