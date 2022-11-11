FROM satosa
USER root
RUN pip install --no-cache-dir satosa[ldap]==${SATOSA_VERSION}
COPY --chown=satosa:satosa *.yaml /etc/satosa/
COPY --chown=satosa:satosa plugins /etc/satosa/
COPY delayed-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["delayed-entrypoint.sh"]
USER satosa:satosa
CMD ["gunicorn","-b0.0.0.0:8080","satosa.wsgi:app"]
