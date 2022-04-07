#!/bin/bash

#trap die ERR

function die()
{
  echo "Failed at line $BASH_LINENO"
  exit 1
}

function curlf() {
  OUTPUT_FILE=$(mktemp)
  HTTP_CODE=$(curl --silent --output $OUTPUT_FILE --write-out "%{http_code}" "$@")
  if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
    >&2 cat $OUTPUT_FILE
    return 22
  fi
  cat $OUTPUT_FILE
  rm $OUTPUT_FILE
}

