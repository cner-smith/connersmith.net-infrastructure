# This imports the necessary modules needed for the script, specifically json, boto3, and os.
import json, boto3, os
# This imports the ClientError class from the botocore.exceptions module.
from botocore.exceptions import ClientError


# Initialize dynamodb boto3 object
dynamodb = boto3.resource('dynamodb')
# Set dynamodb table name variable from env
ddbTableName = os.environ['DYNAMOTABLE']
# This sets a variable table to an instance of the DynamoDB table to be used.
table = dynamodb.Table(ddbTableName)

# This is the main function that is executed when the Lambda function is triggered.
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


    # This returns the response from DynamoDB as an integer to be passed as the body
    responseBody = int(ddbResponse["Attributes"]["hits"])


    # This creates an API response object that includes a header specifying which origins are allowed to make requests,
    # the status code of the response, and the body of the response as the responseBody variable created earlier.
    apiResponse = {
        "isBase64Encoded": False,
        "statusCode": 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
        },
        "body": responseBody
    }


    # Return api response object
    return apiResponse