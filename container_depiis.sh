#!/bin/bash
#!/bin/bash
set -e

if [ ! -f /.dockerenv ] ; then
    echo "This script is meant to be run from inside a docker container. Did you mean to run deploy_iis.sh ?"
    exit 1
fi

aws s3 cp --recursive /sandbox/s3-files ${S3_BUCKET_URI}

if ! aws ec2 describe-key-pairs --key-name ws2012-sandbox ; then
    echo "Sandbox keypair does not exist, creating now."
    aws ec2 create-key-pair --key-name ws2012-sandbox --query 'KeyMaterial' --output text > /sandbox/ws2012-sandbox-key.pem
fi

# TODO: add firewall inbound rules
if ! aws ec2 describe-security-groups --group-names ws2012-sandbox ; then
    echo "Sandbox security group does not exist, creating now."
    aws ec2 create-security-group --group-name ws2012-sandbox --description "Security group for Windows Server 2012 test application"
fi

# image-id points to WS2012 image
aws ec2 run-instances \
    --image-id ami-049d3d4d8ed0f7269 \
    --count 1 \
    --instance-type t2.micro \
    --key-name ws2012-sandbox \
    --security-groups ws2012-sandbox \
    --user-data "$(envsubst < /sandbox/aws-cli/user-data.txt)"
