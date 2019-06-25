# Windows Server 2012/IIS 8.0 Testing Sandbox

Build the aws-cli image:

`docker build -t alpine:aws_cli -f aws-cli/Dockerfile aws-cli/`

Update your environment file with you AWS credentials (see security policy section below for needed permissions) and source it

`source aws_config.env`

Deploy by running the included `deploy_iis.sh` which executes the following procedure via AWS CLI

1. Ensures files from development workspace are synced with amazon s3 bucket for use by the server
2. Deploys EC2 t2.micro instance
3. User data of t2.micro instance executes deploy powershell script located on s3 bucket
4. Powershell script installs IIS and sandbox webiste located on s3 bucket

Site displays currently configured tuning values

AWS CLI Container Implementation adapted from https://github.com/mesosphere/aws-cli

# AWS Service Account Security Policy

See the following for a minimum access security group quickstart
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RunInstances",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:subnet/*",
                "arn:aws:ec2:*:*:key-pair/*",
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*::snapshot/*",
                "arn:aws:ec2:*:*:launch-template/*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:placement-group/*",
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*::image/*",
                "arn:aws:s3:::[BUCKET NAME HERE]",
                "arn:aws:s3:::[BUCKET NAME HERE]/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::[BUCKET NAME HERE]",
                "arn:aws:s3:::[BUCKET NAME HERE]/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:CreateSecurityGroup",
                "ec2:CreateKeyPair",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        }
    ]
}
```
