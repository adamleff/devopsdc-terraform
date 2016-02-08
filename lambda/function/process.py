from datetime import datetime
import boto3
import decimal
import json
import uuid

def do_stuff(event, context):
	print event

	now = datetime.now()
	epochtime = (now-datetime(1970,1,1)).total_seconds()

	for record in event['Records']:
		db_record = {}
		db_record['UUID'] = str(uuid.uuid4())
		db_record['time_processed'] = decimal.Decimal(epochtime)
		db_record['filename'] = record['s3']['object']['key']
		db_record['size'] = record['s3']['object']['size']

	dynamodb = boto3.resource('dynamodb', endpoint_url="https://dynamodb.us-east-1.amazonaws.com")
	table = dynamodb.Table('DevOpsDCFileData')
	table.put_item(Item=db_record)
