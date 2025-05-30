# Standard library imports for JSON manipulation, operating system interactions, and logging.
import json
import os
import logging

# AWS SDK for Python (Boto3) for interacting with AWS services.
import boto3
# Specific exception class from botocore for more granular error handling with AWS services.
from botocore.exceptions import ClientError

# --- Global Configuration and Initialization ---

# Initialize the standard Python logger.
# This allows the function to output logs to Amazon CloudWatch.
logger = logging.getLogger()
# Set the logging level to INFO. Messages of level INFO, WARNING, ERROR, and CRITICAL will be logged.
logger.setLevel(logging.INFO)

# Attempt to initialize DynamoDB resources globally.
# This is a performance optimization for AWS Lambda, as these resources can be reused across invocations
# if the execution environment is warm.
try:
    # Create a Boto3 DynamoDB resource client. This provides a higher-level interface to DynamoDB.
    dynamodb = boto3.resource('dynamodb')
    
    # Retrieve the DynamoDB table name from an environment variable.
    # Environment variables are a secure way to configure Lambda functions without hardcoding values.
    ddbTableName = os.environ.get('DYNAMOTABLE')
    
    # Log an error and proceed if the environment variable is not set.
    # The function will likely fail later if the table name is None, but this provides an early warning.
    if not ddbTableName:
        logger.error("Environment variable DYNAMOTABLE not set. DynamoDB table object may not be initialized correctly.")
        
    # Create a DynamoDB Table resource object, which represents the specific table to interact with.
    table = dynamodb.Table(ddbTableName)
    
except Exception as e:
    # Catch any exceptions during the initialization of DynamoDB resources.
    # This could be due to misconfiguration, IAM permission issues, or other AWS-related problems.
    logger.error(f"CRITICAL: Error initializing DynamoDB resource or table: {str(e)}. The function may not operate correctly.")
    # Set table to None to indicate that initialization failed. This will be checked in the handler.
    table = None 

# Define a constant for the site identifier used as the primary key in the DynamoDB table.
# This makes it easy to reference and change if needed, rather than hardcoding the string multiple times.
SITE_ID = 'connersmith.net' 

# --- Lambda Handler Function ---

def lambda_handler(event, context):
    """
    AWS Lambda handler function. This function is triggered by an event (e.g., API Gateway request).
    It increments a visitor counter in a DynamoDB table and returns the updated count.

    Args:
        event (dict): The event data passed to the Lambda function.
        context (object): The runtime information of the Lambda function.

    Returns:
        dict: An API Gateway proxy response object containing the status code,
              headers (including CORS), and a body with the visitor count or an error message.
    """
    
    # Optional: Log the incoming event for debugging purposes.
    # Useful for understanding the structure of the event data.
    # logger.info(f"Received event: {json.dumps(event)}")

    # Check if the DynamoDB table object was successfully initialized globally.
    # If not, the function cannot proceed with database operations.
    if table is None:
        logger.error("DynamoDB table object is not initialized. Cannot process request.")
        # Return a 500 Internal Server Error response.
        return {
            "isBase64Encoded": False,
            "statusCode": 500,
            'headers': {
                # CORS headers to allow cross-origin requests.
                'Access-Control-Allow-Headers': 'Content-Type',
                # It is recommended to specify the actual domain in production instead of '*'.
                'Access-Control-Allow-Origin': '*', 
                # Specify the HTTP methods allowed for cross-origin requests.
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET' 
            },
            "body": json.dumps({"error": "Server configuration error. Please contact support."})
        }

    try:
        # Atomically update the 'hits' attribute for the item identified by SITE_ID in DynamoDB.
        # The `update_item` operation is used here.
        ddbResponse = table.update_item(
            Key={
                'site_id': SITE_ID  # The primary key of the item to update.
            },
            # UpdateExpression defines the action to perform on the attributes.
            # 'SET hits = if_not_exists(hits, :start_val) + :inc_val' does the following:
            # 1. If the 'hits' attribute does not exist, it initializes it to :start_val (0).
            # 2. It then increments the 'hits' attribute by :inc_val (1).
            # This ensures atomic incrementation, crucial for concurrent updates.
            UpdateExpression='SET hits = if_not_exists(hits, :start_val) + :inc_val',
            ExpressionAttributeValues={
                ':inc_val': 1,     # The value to increment by.
                ':start_val': 0    # The initial value for 'hits' if it doesn't exist.
            },
            # ReturnValues="UPDATED_NEW" specifies that DynamoDB should return the new values
            # of the attributes that were updated.
            ReturnValues="UPDATED_NEW" 
        )

        # Extract the new hit count from the DynamoDB response.
        # The response contains an "Attributes" map with the updated values.
        new_hit_count = int(ddbResponse["Attributes"]["hits"])
        logger.info(f"Successfully updated hit count for '{SITE_ID}' to {new_hit_count}.")

        # Prepare the response body as a JSON string.
        responseBody = json.dumps({"site": SITE_ID, "visitorCount": new_hit_count})

        # Construct the API Gateway proxy response object.
        apiResponse = {
            "isBase64Encoded": False, # Indicates that the body is not Base64 encoded.
            "statusCode": 200,       # HTTP 200 OK status.
            'headers': {
                # Comprehensive CORS headers.
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                # For production, replace '*' with the specific domain of the website making the request.
                'Access-Control-Allow-Origin': '*', 
                # Specify allowed HTTP methods. 'GET' for fetching the count, 'OPTIONS' for preflight requests.
                'Access-Control-Allow-Methods': 'GET,OPTIONS' 
            },
            "body": responseBody # The JSON string containing the visitor count.
        }

    except ClientError as e:
        # Handle errors specific to AWS services (Boto3/Botocore).
        # This can include issues like throttling, access denied, or resource not found.
        logger.error(f"DynamoDB ClientError: {e.response['Error']['Message']}. Error Code: {e.response['Error']['Code']}")
        apiResponse = {
            "isBase64Encoded": False,
            "statusCode": 500, # Internal Server Error.
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            # Provide a more specific error message if possible, including details from the exception.
            "body": json.dumps({"error": "Could not update visitor count due to a database error.", 
                                "details": e.response['Error']['Message']})
        }
    except Exception as e:
        # Catch any other unexpected exceptions that were not caught by ClientError.
        logger.error(f"An unexpected error occurred: {str(e)}", exc_info=True) # exc_info=True logs stack trace
        apiResponse = {
            "isBase64Encoded": False,
            "statusCode": 500, # Internal Server Error.
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            "body": json.dumps({"error": "An unexpected server error occurred. Please try again later."})
        }

    # Return the final API response object.
    return apiResponse
