#!/usr/bin/env bash

set -Eeuo pipefail

SECRET_ARN="$1"
COMMON_NAME="$2"

SECRET_VALUE="$(
	aws secretsmanager get-secret-value \
		--secret-id "${SECRET_ARN}" --query SecretString \
		--output text
)"

if [ "${SECRET_VALUE}" = "030373bb-ddf8-44d6-8213-7c9ff2339316" ]; then
	TEMP_DIR="$(mktemp -d)"
	openssl req -x509 -newkey rsa:4096 -days 3650 -sha512 -nodes \
		-subj "/CN=${COMMON_NAME}" \
		-outform PEM -out "${TEMP_DIR}/cert.pem" -keyout "${TEMP_DIR}/key.pem" \
		-batch
	aws secretsmanager put-secret-value \
		--secret-id "${SECRET_ARN}" --secret-string "$(
			jq -n \
				--rawfile cert ${TEMP_DIR}/cert.pem \
				--rawfile key ${TEMP_DIR}/key.pem \
				'{certificate: $cert, key: $key}'
		)"
fi
