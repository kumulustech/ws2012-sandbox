# Windows Server 2012/IIS 8.0 Testing Sandbox

Build the aws-cli image:

`docker build -t alpine:aws_cli -f aws-cli/Dockerfile aws-cli/`

Update your environment file with you AWS credentials and source it

`source aws_config.env`

Deploy by running the included `deploy_iis.sh` which executes the following procedure via AWS CLI

1. Ensures files from development workspace are synced with amazon s3 bucket for use by the server
2. Deploys EC2 t2.micro instance
3. User data of t2.micro instance executes deploy powershell script located on s3 bucket
4. Powershell script installs IIS and sandbox webiste located on s3 bucket

Site displays currently configured tuning values

AWS CLI Container Implementation adapted from https://github.com/mesosphere/aws-cli