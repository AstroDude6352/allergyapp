import json
import boto3

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')

def handler(event, context):
    print("Received event:", json.dumps(event))

    # Parse query string params (e.g., ?bucket=mybucket&key=myimage.jpg)
    params = event.get('queryStringParameters') or {}

    bucket = params.get('bucket')
    key = params.get('key')

    if not bucket or not key:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing bucket or key in query parameters'})
        }

    try:
        # Get the image from S3
        s3_object = s3.get_object(Bucket=bucket, Key=key)
        image_bytes = s3_object['Body'].read()

        # Send to Rekognition
        response = rekognition.detect_labels(
            Image={'Bytes': image_bytes},
            MaxLabels=10,
            MinConfidence=70
        )

        labels = [label['Name'] for label in response['Labels']]

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'labels': labels})
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
