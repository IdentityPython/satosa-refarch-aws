#!/usr/bin/env bash

. /usr/local/bin/docker-entrypoint.sh

if ! _is_sourced; then
	# delay start until keymat appears (default max. ~300s); cf.
	# https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/680
	i=${STARTUP_DELAY}
	while [ $i -gt 0 ]; do
		((i--))
		sleep 1
		for secret in \
			/run/secrets/saml2_{back,front}end/{certificate,key} \
			/run/secrets/state_encryption_key \
		; do
			if [ ! -f "${secret}" ]; then break; fi
			i=0
		done
	done

	_main "$@"
fi
