import json, boto3, os
from botocore.exceptions import ClientError

def get_key(pid, intable, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table(intable)

    try:
        response = table.update_item(
            TableName=intable,
            Key={"site_id": pid},
            UpdateExpression='ADD hits :inc',
            ExpressionAttributeValues={
                ':inc': 1
            },
            ReturnValues="UPDATED_NEW"
        )
    except ClientError as e:
        print(e.response)
    else:
        return response

def lambda_handler(event, context):
    #name of the table
    TABLEVAR = "visitor_count"
    #calls get_key to retrieve and update the value of hits
    hits = get_key("connersmith.net", TABLEVAR)
    if hits:
        return {
            "statusCode": 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': 'https://connersmith.net',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },       
            "body": json.dumps({
                "count": str(hits['Attributes']['hits']),
            }),
        }
    return {
        "statusCode": 200,
         'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': 'https://connersmith.net',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },       
        "body": json.dumps({
            "count": "0001",
        }),
    }
