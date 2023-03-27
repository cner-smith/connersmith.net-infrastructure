import json, boto3, os
from botocore.exceptions import ClientError


# Initialize dynamodb boto3 object
dynamodb = boto3.resource('dynamodb')
# Set dynamodb table name variable from env
ddbTableName = os.environ['DYNAMOTABLE']
table = dynamodb.Table(ddbTableName)


def lambda_handler(event, context):
    # Update item in table or add if doesn't exist
    ddbResponse = table.update_item(
        Key={
            'site_id': 'connersmith.net'
        },
        UpdateExpression='SET hits = hits + :value',
        ExpressionAttributeValues={
            ':value':1
        },
        ReturnValues="UPDATED_NEW"
    )


    # Format dynamodb response into variable
    responseBody = json.dumps({"connersmith.net": int(ddbResponse["Attributes"]["hits"])})


    # Create api response object
    apiResponse = {
        "isBase64Encoded": False,
        "statusCode": 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        "body": responseBody
    }


    # Return api response object
    return apiResponse