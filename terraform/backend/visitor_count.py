import boto3, json
from botocore.exceptions import ClientError

def get_key(pid, intable, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table(intable)

    try:
        response = table.update_item(
            Key={
                "site-id": "index"
            },
            UpdateExpression='ADD hitcount :inc',
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

    TABLEVAR = os.getenv('DYNAMOTABLE')
    hits = get_key("index",TABLEVAR,)
    if hits:
        return {
            "statusCode": 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': 'https://connersmith.net',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },       
            "body": json.dumps({
                "count": str(hits['Attributes']['hitcount']),
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