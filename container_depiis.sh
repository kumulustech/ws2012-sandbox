#!/bin/bash
set -e

if [ ! -f /.dockerenv ] ; then
    echo "This script is meant to be run from inside a docker container. Did you mean to run deploy_iis.sh ?"
    exit 1
fi

# Set up S3 resources
if ! S3_BUCKET_REGION=`aws s3api get-bucket-location --bucket $S3_BUCKET_NAME --query "LocationConstraint" --output text` ; then
    echo "Bucket $S3_BUCKET_NAME does not exist, attempting to create now"
    S3_BUCKET_REGION=$AWS_DEFAULT_REGION
    aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $S3_BUCKET_REGION --create-bucket-configuration LocationConstraint=${S3_BUCKET_REGION}
fi

export S3_BUCKET_REGION

aws s3 cp --recursive /sandbox/s3-files s3://${S3_BUCKET_NAME}/${S3_BUCKET_KEY} --region $S3_BUCKET_REGION

# Verify IAM config for SSM access. Role is needed since it willl be attached to the instance
INST_PROF_NAME="InstanceProfileAmazonSSMManagedInstanceCore"

if "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" -neq $(aws iam list-attached-role-policies --role-name $INST_PROF_NAME --query 'AttachedPolicies[?PolicyName==`AmazonSSMManagedInstanceCore`].PolicyArn' --output text); then
    printf "Instance profile named %s (with attached amazon managed role AmazonSSMManagedInstanceCore) is required for SSM to manage EC2 instances \n" $INST_PROF_NAME
    exit 1 # Only doing a validation here to avoid attaching iam create permissions to a service account
fi

# Set up EC2 resources and deploy instance
if ! aws ec2 describe-key-pairs --key-name ws2012-sandbox ; then
    echo "Sandbox keypair does not exist, creating now."
    aws ec2 create-key-pair --key-name ws2012-sandbox --query 'KeyMaterial' --output text > /sandbox/ws2012-sandbox-key.pem
fi

if ! aws ec2 describe-security-groups --group-names ws2012-sandbox ; then
    echo "Sandbox security group does not exist, creating now."
    aws ec2 create-security-group --group-name ws2012-sandbox --description "Security group for Windows Server 2012 test application"

    # authorize rdp for runner of the script
    aws ec2 authorize-security-group-ingress --group-name ws2012-sandbox \
        --ip-permissions IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges="[{CidrIp=$(curl https://checkip.amazonaws.com/)/32,Description='RDP access from deployment host'}]"
    
    # authorize web for everyone
    aws ec2 authorize-security-group-ingress --group-name ws2012-sandbox \
        --ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges="[{CidrIp=0.0.0.0/0,Description='HTTP access'}]",Ipv6Ranges="[{CidrIpv6=::/0,Description='HTTP access'}]"

    # authorize describe access for everyone 
    # TODO: restrict to servo known IPs
    # aws ec2 authorize-security-group-ingress --group-name ws2012-sandbox \
    #     --ip-permissions IpProtocol=tcp,FromPort=8080,ToPort=8080,IpRanges="[{CidrIp=0.0.0.0/0,Description='HTTP describe access'}]",Ipv6Ranges="[{CidrIpv6=::/0,Description='HTTP describe access'}]"
fi

WS2012_IMAGE_ID=`aws ec2 describe-images --owners amazon --filters "Name=name,Values=Windows_Server-2012-RTM-English-64Bit-Base*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text`

# Note: envsubst is used to populate the current env sa credentials into the user-data.txt file (see $ vars in file). 
#       TODO: This is insecure and should be replaced with an iam ec2 instance profile in production
CREATE_OUTPUT=`aws ec2 run-instances \
    --image-id $WS2012_IMAGE_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name ws2012-sandbox \
    --security-groups ws2012-sandbox \
    --iam-instance-profile Name="$INST_PROF_NAME" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=group,Value=servo}, {Key=role,Value=testing}]'
    --user-data "$(envsubst < /sandbox/aws-cli/user-data.txt)"`

# Poll instance state during deployment and update prompt when complete
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
printf "Test website ready; enter %s into your browser\n" $PUB_IP
