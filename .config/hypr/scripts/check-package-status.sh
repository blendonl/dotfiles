#!/usr/bin/env bash

user=$(curl -H 'Content-Type: application/json' \
    -d '{ "email":'"\"$USER_EMAIL\""',"password":'"\"$USER_PASSWORD\""' }' \
      -X POST \
      https://api.paketos.io/login)



access_token=$(echo "$user" | jq -r '.access_token')




package=$(curl -H 'Authorization: Bearer '$access_token \
'https://api.paketos.io/package/'$PACKAGE'?select=id,number_prefix,shipment_type_id,client_user_id,carrier,carrier_tracking,order_id,height,width,length,weight,recipient_name,signature,eta,delivered_at,created_at&include=lastClientTrackingHistory.status;descriptions&append=clientAddress;availableToReturn;bills'
)


tracking_hist=$(echo "$package" | jq -r '.package.last_client_tracking_history')

status_name=$(echo "$package" | jq -r '.package.last_client_tracking_history.status_name')
status_display_name=$(echo "$package" | jq -r '.package.last_client_tracking_history.status.client_display_name')
package_id=$(echo "$package" | jq -r '.package.id')



notify-send "Status for package $package_id" "Status: $status_name \nName: $status_display_name"
