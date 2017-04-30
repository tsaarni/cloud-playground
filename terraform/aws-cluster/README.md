
#

## Preparation

### Create user

Go to [IAM console](https://console.aws.amazon.com/iam/home?region=us-east-1#/home) and select Users / Add User, access type Programmable access


https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html


store in ~/.aws/credentials

the file format is

    [default]
    aws_access_key_id=NNN
    aws_secret_access_key=NNN


See http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html


Create group with following policies attached

* AmazonEC2FullAccess
* AmazonEC2SpotFleetRole
* IAMReadOnlyAccess
