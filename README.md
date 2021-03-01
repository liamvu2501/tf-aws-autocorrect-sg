# Serverless Autocorrect Security Groups

This repo contains Terraform modules and scripts that help you to monitor and revert changes in the Inbound & Outbound rules of your Security Groups. Any newly added Inbound & Outbound rules will be revoked automatically and notifications will be sent out.

## Prerequisites

1. Cloudtrail is enabled in your environment.
2. Install Terraform. Refer to [here](https://www.terraform.io/downloads.html)
3. awscli is configured in your environment. Terraform will use your awscli credentials to create the environment.
4. The repo will not work for cross-region. You need to deploy this repo to all regions that you want to monitor. 


## Architecture

A serverless architecture with AWS CloudTrail, EventBridge, Lambda and SNS will be used.

<img src="https://github.com/liamvu2501/tf-aws-autocorrect-sg/blob/main/Architecture_Diagram.PNG" width="600" height="400" />


## How to run

1. Clone this repo:

```bash
git clone https://github.com/liamvu2501/tf-aws-autocorrect-sg.git
```

2. Create a **terraform.tfvars** file in the same directory of the **main.tf** and fill in your info. Refer to **terraform.tfvars.example** in this repo as an example


3. This repo will use your awscli "default" profile. If you want to change it, please open **provider.tf** and modify `profile = "default"` to `profile = "yourprofile"`. Make sure to use the profile that has appropriate permissions to create the environment

You can also change the region to deploy this repo. Open **provider.tf** and modify `region  = "us-east-2"` to `region  = "yourregion"` . Make sure to match the `region` specify in **provider.tf** with the `region` in your **terraform.tfvars**


3. At the root of the repo/folder, init your environment:

```bash
terraform init
```

4. Plan and apply:

```bash
terraform plan
terraform apply -auto-approve
```

5. Check the email that you specify in the **terraform.tfvars** in step 2 and confirm the subscription


6. Sit back, relax and let Lambda does the heavy work


## Disclaimer

All writers's opinions are their own. Please contact AWS and Hashicorp if you need official supports for any services. Feel free to clone the repo, modify it and create pull requests if necessary.




