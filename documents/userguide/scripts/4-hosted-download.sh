#!/bin/bash
set -e

printenv DOMAIN > /dev/null

# tag::public[]
id=$1

curl -S -s -X GET \
    -u $PZUSER:$PZPASS \
    -w "%{http_code}" \
    -o response.txt \
    "https://pz-gateway.$DOMAIN/file/$id?fileName=terrametrics.tif" > status.txt

# verify all worked successfully
grep -q 200 status.txt
# end::public[]

rm -f response.txt status.txt
