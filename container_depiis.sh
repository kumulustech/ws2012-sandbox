#!/bin/bash
set -e

if [ ! -f /.dockerenv ] ; then
    echo "This script is meant to be run from inside a docker container. Did you mean to run deploy_iis.sh ?"
    exit 1
fi

aws s3 cp --recursive /sandbox/s3-files s3://${S3_BUCKET_NAME}/${S3_BUCKET_KEY}

if ! aws ec2 describe-key-pairs --key-name ws2012-sandbox ; then
    echo "Sandbox keypair does not exist, creating now."
    aws ec2 create-key-pair --key-name ws2012-sandbox --query 'KeyMaterial' --output text > /sandbox/ws2012-sandbox-key.pem
fi

# TODO: add firewall inbound rules
if ! aws ec2 describe-security-groups --group-names ws2012-sandbox ; then
    echo "Sandbox security group does not exist, creating now."
    aws ec2 create-security-group --group-name ws2012-sandbox --description "Security group for Windows Server 2012 test application"

    # authorize rdp for runner of the script
    aws ec2 authorize-security-group-ingress --group-name ws2012-sandbox \
        --ip-permissions IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges="[{CidrIp=$(curl https://checkip.amazonaws.com/)/32,Description='RDP access from deployment host'}]"
    
    # authorize web for everyone
    aws ec2 authorize-security-group-ingress --group-name ws2012-sandbox \
        --ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges="[{CidrIp=0.0.0.0/0,Description='HTTP access'}]",Ipv6Ranges="[{CidrIpv6=::/0,Description='HTTP access'}]"
fi

# image-id points to WS2012 image
CREATE_OUTPUT=`aws ec2 run-instances \
    --image-id ami-049d3d4d8ed0f7269 \
    --count 1 \
    --instance-type t2.micro \
    --key-name ws2012-sandbox \
    --security-groups ws2012-sandbox \
    --user-data "$(envsubst < /sandbox/aws-cli/user-data.txt)"`

INST_ID=`echo $CREATE_OUTPUT | jq -r '.Instances | first.InstanceId'`

echo -n 'Waiting for instance to be in running state.'

until [ $(aws ec2 describe-instances --instance-ids $INST_ID | jq -r '.Reservations | first.Instances | first.State.Name') == 'running' ] ; do
    echo -n '.'
    sleep 5
done
echo ''

PUB_IP=$(aws ec2 describe-instances --instance-ids $INST_ID | jq -r '.Reservations | first.Instances | first.PublicIpAddress')

echo -n 'Waiting for test website.'
until curl -m 5 -s $PUB_IP | grep -q 'Hello' ; do
    echo -n '.'
    sleep 5
done

echo ''
printf "Test website ready; enter %s into your browser" $PUB_IP
