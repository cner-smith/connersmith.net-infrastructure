import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const TABLE  = process.env.DYNAMOTABLE;
const SITE   = 'connersmith.net';

const HEADERS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
};

export const handler = async () => {
  try {
    const res = await client.send(new UpdateCommand({
      TableName: TABLE,
      Key: { site_id: SITE },
      UpdateExpression: 'SET hits = if_not_exists(hits, :start) + :inc',
      ExpressionAttributeValues: { ':inc': 1, ':start': 0 },
      ReturnValues: 'UPDATED_NEW',
    }));

    return {
      statusCode: 200,
      headers: HEADERS,
      body: JSON.stringify({
        site: SITE,
        visitorCount: Number(res.Attributes.hits),
      }),
    };
  } catch (err) {
    console.error('DynamoDB error:', err);
    return {
      statusCode: 500,
      headers: HEADERS,
      body: JSON.stringify({ error: 'Could not update visitor count.' }),
    };
  }
};