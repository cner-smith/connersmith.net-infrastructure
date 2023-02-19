import boto3

# Define the DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Define the table name
table_name = 'visitor_count'

# Define the Lambda function handler
def handler(event, context):
    # Retrieve the DynamoDB table
    table = dynamodb.Table(table_name)

    # Get the item with the key 'count'
    response = table.get_item(
        Key={
            'key': 'count'
        }
    )

    # Extract the visitor count from the response
    count = response['Item']['count']

    # Increment the count by 1
    count += 1

    # Write the new count back to the DynamoDB table
    table.put_item(
        Item={
            'key': 'count',
            'count': count
        }
    )

    # Return the visitor count as a string
    return str(count)