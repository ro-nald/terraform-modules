# EC2 deployment to the AWS Hong Kong region ap-east-1

An EC2 instance (t4g.nano by default) deployed to a specified region with EBS Volume (gp3 10GB by default), deployed with a Data Lifecycle Manager (DLM) policy to create a snapshot every day and retain for 7 days by default.

## Back-up protocol in the event of a crash

1. Launch a new EC2 in a different AZ.
2. Attach the latest snapshot.
3. Update your Domain (DNS) to point to the new IP.
