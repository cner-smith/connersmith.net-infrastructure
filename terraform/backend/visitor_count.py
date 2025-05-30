import json
import boto3
import os
import logging
from botocore.exceptions import ClientError

# Initialize logger
# Best practice to set up logging for better observability in Lambda
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize dynamodb boto3 resource outside the handler for better performance
# Lambda execution environments can reuse these global variables across invocations
try:
    dynamodb = boto3.resource('dynamodb')
    # It's good practice to ensure the environment variable is actually set
    ddbTableName = os.environ.get('DYNAMOTABLE')
    if not ddbTableName:
        logger.error("Environment variable DYNAMOTABLE not set.")
        # You might want to raise an exception here or handle it depending on
        # whether the Lambda should fail completely if the table name isn't set.
        # For this example, we'll let it proceed and fail at table initialization if name is None.
    table = dynamodb.Table(ddbTableName)
except Exception as e:
    # Catching potential errors during initialization (e.g., IAM permissions, misconfiguration)
    logger.error(f"Error initializing DynamoDB resource or table: {str(e)}")
    # If initialization fails, the Lambda probably can't do its job.
    # Depending on the desired behavior, you could raise the exception
    # to cause a cold start failure, which CloudWatch will catch.
    table = None # Ensure table is None if initialization failed

SITE_ID = 'connersmith.net' # Use a constant for the site ID

def lambda_handler(event, context):
    # Log the incoming event (optional, but can be useful for debugging)
    # logger.info(f"Received event: {json.dumps(event)}")

    if table is None:
        logger.error("DynamoDB table not initialized. Exiting.")
        return {
            "isBase64Encoded": False,
            "statusCode": 500, # Internal Server Error
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*', # Be specific with your domain in production if possible
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET' # Only allow methods you actually use
            },
            "body": json.dumps({"error": "Server configuration error."})
        }

    try:
        # Update item in table or add if it doesn't exist.
        # The 'SET hits = hits + :value' expression works well.
        # If 'hits' doesn't exist on the item, DynamoDB creates it and sets it to :value.
        # If the item itself doesn't exist, DynamoDB creates the item with the key and 'hits'.
        ddbResponse = table.update_item(
            Key={
                'site_id': SITE_ID
            },
            # Using if_not_exists ensures that 'hits' is initialized to 0 if it doesn't exist,
            # then adds :value. If it already exists, it just adds :value.
            # This makes the first hit result in 1 (0 + 1).
            UpdateExpression='SET hits = if_not_exists(hits, :start_val) + :inc_val',
            ExpressionAttributeValues={
                ':inc_val': 1,
                ':start_val': 0 # Initialize to 0 if 'hits' attribute does not exist
            },
            ReturnValues="UPDATED_NEW" # Returns the new value of the attribute(s) updated
        )

        new_hit_count = int(ddbResponse["Attributes"]["hits"])
        logger.info(f"Successfully updated hit count for {SITE_ID} to {new_hit_count}")

        # Standardize response body slightly
        responseBody = json.dumps({"site": SITE_ID, "visitorCount": new_hit_count})

        apiResponse = {
            "isBase64Encoded": False,
            "statusCode": 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token', # More comprehensive headers
                'Access-Control-Allow-Origin': '*', # For production, ideally replace '*' with your actual domain e.g., 'https://connersmith.net'
                'Access-Control-Allow-Methods': 'GET,OPTIONS' # If this Lambda is only for GET requests
            },
            "body": responseBody
        }

    except ClientError as e:
        logger.error(f"DynamoDB ClientError: {e.response['Error']['Message']}")
        apiResponse = {
            "isBase64Encoded": False,
            "statusCode": 500, # Internal Server Error
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            "body": json.dumps({"error": "Could not update visitor count.", "details": e.response['Error']['Message']})
        }
    except Exception as e:
        logger.error(f"An unexpected error occurred: {str(e)}")
        apiResponse = {
            "isBase64Encoded": False,
            "statusCode": 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            "body": json.dumps({"error": "An unexpected server error occurred."})
        }

    return apiResponse