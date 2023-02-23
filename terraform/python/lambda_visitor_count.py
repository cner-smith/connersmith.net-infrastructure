import boto3
import os
import json
from boto3.dynamodb.conditions import Key

ddbName = "${var.aws_dynamodb_table_name}"

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(ddbName) 

#returns the latest value
def get_count():
   response = table.query(
       KeyConditionExpression=Key('site_id').eq('site_id')
       )
   count = response['Items'][0]['visitor_count']
   return count

#increment the visits value
def lambda_handler(event, context):
   response = table.update_item(     
       Key={        
           'site_id': 'site_id',
       },   
       UpdateExpression='ADD ' + 'visitor_count' + ' :incr',
       ExpressionAttributeValues={        
           ':incr': 1   
       },    
       ReturnValues="UPDATED_NEW"
   )

# Headers for API calls
   return {
       'statusCode': 200,
       'headers': {
           'Access-Control-Allow-Origin': '*',
           'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
           'Access-Control-Allow-Credentials': 'true',
           'Content-Type': 'application/json'
       },
       'body': get_count()
   }