#!/bin/bash
# https://community.hortonworks.com/questions/83437/ambari-export-blueprint.html
curl -H "X-Requested-By: ambari" \
-X GET \
-u admin:admin http://node1-sb.hortonworks.com:8080/api/v1/clusters/MarketingLab?format=blueprint \
| tee -a blueprint-hdp3-0-data-access.json
