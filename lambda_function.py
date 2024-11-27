import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Lambda function started.")
    stop_ec2_instances()
    stop_rds_instances()
    stop_ecs_services()
    stop_eks_clusters()
    logger.info("Lambda function completed.")

def stop_ec2_instances():
    ec2 = boto3.client('ec2')
    try:
        # Describe running instances
        instances = ec2.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        instance_ids = []
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            ec2.stop_instances(InstanceIds=instance_ids)
            logger.info(f"Stopping EC2 instances: {instance_ids}")
        else:
            logger.info("No running EC2 instances found.")
    except Exception as e:
        logger.error(f"Error stopping EC2 instances: {e}")

def stop_rds_instances():
    rds = boto3.client('rds')
    try:
        # Describe RDS instances
        rds_instances = rds.describe_db_instances()
        rds_instance_ids = [db['DBInstanceIdentifier'] for db in rds_instances['DBInstances']]
        
        if rds_instance_ids:
            for db_id in rds_instance_ids:
                rds.stop_db_instance(DBInstanceIdentifier=db_id)
                logger.info(f"Stopping RDS instance: {db_id}")
        else:
            logger.info("No running RDS instances found.")
    except Exception as e:
        logger.error(f"Error stopping RDS instances: {e}")

def stop_ecs_services():
    ecs = boto3.client('ecs')
    try:
        clusters = ecs.list_clusters()['clusterArns']
        for cluster in clusters:
            services = ecs.list_services(cluster=cluster)['serviceArns']
            for service in services:
                ecs.update_service(cluster=cluster, service=service, desiredCount=0)
                logger.info(f"Stopping ECS service: {service} in cluster: {cluster}")
    except Exception as e:
        logger.error(f"Error stopping ECS services: {e}")

def stop_eks_clusters():
    eks = boto3.client('eks')
    try:
        clusters = eks.list_clusters()['clusters']
        for cluster in clusters:
            nodegroups = eks.list_nodegroups(clusterName=cluster)['nodegroups']
            for nodegroup in nodegroups:
                eks.update_nodegroup_config(
                    clusterName=cluster,
                    nodegroupName=nodegroup,
                    scalingConfig={'desiredSize': 0}
                )
                logger.info(f"Scaling down EKS nodegroup: {nodegroup} in cluster: {cluster}")
    except Exception as e:
        logger.error(f"Error stopping EKS clusters: {e}")
