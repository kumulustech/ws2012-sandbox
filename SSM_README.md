# SSM POC info

## Requirements:
doc: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-prereqs.html

1. First, define the Run Command documents `Servo-Describe` and `Servo-Adjust` within SSM using the following aws doc site with the files `RunCommandAdjust.yaml` and `RunCommandDescribe.yaml`
    - https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-console.html
1. In order for SSM to run commands on an instance, the **EC2 instance** itself must have a role attached that contains the managed policy AmazonSSMManagedInstanceCore.
    - This is most easily accomplished with an instance profile as documented here: https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-console
    - Note: the IAM user which launches the instance and/or attaches the Instance Profile must have an IAM permission of iam:PassRole with the desired Instance profile specified as the resource
1. Next, in order to execute SSM commands against an instance, the user making the API call to SSM must have at least the ssm:SendCommand permission both on the target instance as well as the documents to be run on the target instance. 
    - Note EC2 ssm access can be easily restricted to instances with certain tags as demonstrated below
    - https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-rc-setting-up-cmdsec.html
    - Example:
        ```
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "VisualEditor0",
              "Effect": "Allow",
              "Action": "ssm:SendCommand",
              "Resource": [
                "arn:aws:ssm:*:535555670433:document/Servo-Describe",
                "arn:aws:ssm:*:535555670433:document/Servo-Adjust"
              ]
            },
            {
              "Sid": "VisualEditor1",
              "Effect": "Allow",
              "Action": "ssm:SendCommand",
              "Resource": [
                "arn:aws:ec2:*:*:instance/*"
              ],
              "Condition": {
                "StringLike": {
                  "ssm:resourceTag/group": [
                    "servo"
                  ],
                  "ssm:resourceTag/role": [
                    "testing"
                  ]
                }
              }
            }
          ]
        }
        ```

1. Finally, the commands can be tested against an instance with one of the following methods (Note: these are example and you will need to substitute the values as desired):
    - `aws ssm send-command --document-name "Servo-Adjust" --document-version "1" --targets "Key=instanceids,Values=i-05db711acabe74b71" --parameters '{"UriEnableCache": ["false"], "UriScavengerPeriod": ["240"], "WebConfigCacheEnabled": ["false"], "WebConfigEnableKernelCache": ["false"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region us-east-2`
    - AWS Console Run Command Instructions: https://docs.aws.amazon.com/systems-manager/latest/userguide/rc-console.html