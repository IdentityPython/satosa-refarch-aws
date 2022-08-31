FROM satosa
USER root
RUN pip install --no-cache-dir satosa[ldap]==${SATOSA_VERSION}
COPY --chown=satosa:satosa . /etc/satosa/
USER satosa
