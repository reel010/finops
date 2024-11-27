import boto3

ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')

def lambda_handler(event, context):
    
    print(f"Received event: {event}")
    
    # Stop EC2 instances
    try:
        instances = ec2_client.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        instance_ids = []
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            ec2_client.stop_instances(InstanceIds=instance_ids)
            print(f"Stopping EC2 instances: {instance_ids}")
        else:
            print("No running EC2 instances found.")
    except Exception as e:
        print(f"Error stopping EC2 instances: {e}")
    
    # Stop RDS instances
    try:
        rds_instances = rds_client.describe_db_instances()
        rds_instance_ids = [db['DBInstanceIdentifier'] for db in rds_instances['DBInstances']]
        
        if rds_instance_ids:
            for db_id in rds_instance_ids:
                rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
                print(f"Stopping RDS instance: {db_id}")
        else:
            print("No running RDS instances found.")
    except Exception as e:
        print(f"Error stopping RDS instances: {e}")
    
    return {
        'statusCode': 200,
        'body': 'Resources stopped successfully.'
    }
