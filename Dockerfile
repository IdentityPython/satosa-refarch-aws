FROM satosa
USER root
RUN pip install --no-cache-dir satosa[ldap]==${SATOSA_VERSION}
COPY delayed-entrypoint.sh /usr/local/bin/
COPY --chown=satosa:satosa *.yaml /etc/satosa/
COPY --chown=satosa:satosa plugins /etc/satosa/
ENTRYPOINT ["delayed-entrypoint.sh"]
USER satosa:satosa
