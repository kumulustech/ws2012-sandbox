#!/bin/bash
#!/bin/bash
set -e

if [ ! -f /.dockerenv ] ; then
    echo "This script is meant to be run from inside a docker container. Did you mean to run deploy_iis.sh ?"
    exit 1
fi

aws s3 cp /sandbox/s3-files ${S3_BUCKET_URI}

aws ec2 create-key-pair --key-name ws2012-sandbox --query 'KeyMaterial' --output text > /sandbox/ws2012-sandbox-key.pem

aws ec2 create-security-group --group-name ws2012-sandbox --description "Security group for Windows Server 2012 test application"

aws ec2 run-instances \
    --image-id ami-049d3d4d8ed0f7269 \ # WS2012 image
    --count 1 \
    --instance-type t2.micro \
    --key-name ws2012-sandbox \
    --security-groups ws2012-sandbox \
    --user-data ${ envsubst < user-data.txt }
