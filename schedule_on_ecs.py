#!/usr/bin/python

import sys
import boto3

if len(sys.argv) != 2:
  print("Usage:   %s [repo]" % sys.argv[0]);
  print("Example: %s github.com/raboof/connbeat" % sys.argv[0]);
  exit(-1)

owner = sys.argv[1].split('/')[1]
project = sys.argv[1].split('/')[2]

client = boto3.client('ecs')
response = client.run_task(
  cluster='glidebot',
  taskDefinition='glidebot_task:1',
  overrides={ 
    'containerOverrides': [ 
      { 
        'name': 'glidebot_task',
        'environment': [ 
          { 
            'name': 'USER',
            'value': 'root'
          },
          { 
            'name': 'OWNER',
            'value': owner
          },
          { 
            'name': 'PROJECT',
            'value': project
          }
        ]
      }
    ]
  }
)
print(response);
