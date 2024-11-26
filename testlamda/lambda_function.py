import json
import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # Get the bucket name and file key from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # Get the file content
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    
    # Process the content (e.g., count words)
    word_count = len(content.split())
    
    print(f"File {key} in bucket {bucket} has {word_count} words.")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed file {key} with {word_count} words')
    }