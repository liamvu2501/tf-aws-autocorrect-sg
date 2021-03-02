import json
import boto3
import sys
import os

#Declare AWS CDK objects
sns = boto3.client('sns',region_name=os.environ['region'])
ec2_client = boto3.client('ec2')



#Send email
def sns_publish(sns_subj, sns_message):
    sns.publish(TopicArn=os.environ['topic_arn'], Subject=sns_subj, Message=sns_message)

#Format email before sending
def email_format(sg_id,user,user_type,account_id,time,function_name):
    sns_subj = "Security Group alert!"
    sns_message = """
    Hello. There was an attempt to modify the existing security group - {}.
    The attempt came from:
    
    ===============================
    User:   {}
    Type:   {}
    In account:   {}
    Time:   {}
    ===============================
    
    We have reverted the changes. If you do not want the changes to be reverted, please disable the event source for this function - {}.
    
    """.format(sg_id,user,user_type,account_id,time,function_name)
    sns_publish(sns_subj, sns_message)



#Transform JSON-type event data
def transform_event_data(event_detail):
    items = event_detail['requestParameters']['ipPermissions']['items']
    IpPermissions = []
    
    #Loop through each ipPermissions item to get inputs for the revoke_ingress & revoke_egress functions 
    for item in items:
        ipranges = []
        ipv6ranges = []
        sg_groups = []
        prefix_ids = []
        
        #Loop through each item in 'ipRanges' and add them to the ipranges list
        if item['ipRanges']:
            for iprange in item['ipRanges']['items']:
                ipranges.append({'CidrIp' : iprange['cidrIp']})
        
        #Loop through each item in 'ipv6Ranges' and add them to the ipv6ranges list
        if item['ipv6Ranges']:
            for ipv6range in item['ipv6Ranges']['items']:
                ipv6ranges.append({'CidrIpv6': ipv6range['cidrIpv6']})
        
        #Loop through each item in 'groups' and add them to the sg_groups list
        if item['groups']:
            for sg_group in item['groups']['items']:
                sg_groups.append({'GroupId': sg_group['groupId']})
        
        #Loop through each item in 'prefixListIds and add them to the prefix_ids list
        if item['prefixListIds']:
            for prefix_id in item['prefixListIds']['items']:
                prefix_ids.append({'PrefixListId': prefix_id['prefixListId']})

        #Construct the ipPermissions for each item under items
        ipPermissions={
                'IpProtocol': item['ipProtocol'],
                'FromPort': item['fromPort'],
                'ToPort': item['toPort'],
                'UserIdGroupPairs': sg_groups,
                'IpRanges': ipranges,
                'Ipv6Ranges': ipv6ranges,
                'PrefixListIds': prefix_ids
            }

        #Construct the IpPermissions list to pass as an input to revoke_ingress & revoke_egress functions    
        IpPermissions.append(ipPermissions)

    return IpPermissions     
            
#Revoke newly added ingress rules
def revoke_ingress(sg_id, event_detail):
    ec2_client.revoke_security_group_ingress(GroupId=sg_id,IpPermissions=transform_event_data(event_detail))

#Revoke newly added egress rules
def revoke_egress(sg_id, event_detail):
    ec2_client.revoke_security_group_egress(GroupId=sg_id,IpPermissions=transform_event_data(event_detail))



#Main handler
def lambda_handler(event, context):

    #If detect adding new Ingress rules, remove newly added rules and send notifications  
    if event['detail']['eventName'] == 'AuthorizeSecurityGroupIngress':

        sg_id = event['detail']['requestParameters']['groupId']
        user = event['detail']['userIdentity']['userName']
        user_type = event['detail']['userIdentity']['type']
        account_id = event['detail']['userIdentity']['accountId']
        time = event['detail']['eventTime']
    
        #Invoke the revoke_ingress function to remove newly added rules
        revoke_ingress(sg_id,event['detail'])
        
        #Send notifications
        email_format(sg_id,user,user_type,account_id,time,os.environ['function_name'])


    #If detect adding new Egress rules, remove newly added rules and send notifications  
    if event['detail']['eventName'] == 'AuthorizeSecurityGroupEgress':

        sg_id = event['detail']['requestParameters']['groupId']
        user = event['detail']['userIdentity']['userName']
        user_type = event['detail']['userIdentity']['type']
        account_id = event['detail']['userIdentity']['accountId']
        time = event['detail']['eventTime']

        #Invoke the revoke_egress function to remove newly added rules
        revoke_egress(sg_id,event['detail'])
        
        #Send notifications
        email_format(sg_id,user,user_type,account_id,time,os.environ['function_name'])
