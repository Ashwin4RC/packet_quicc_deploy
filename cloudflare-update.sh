#!/bin/bash

api_token="$1"
zone_name="$3"
record_name="$2.$3"
proxied="$4"

ip=$(ip addr | grep bond0 | grep inet | awk '{$1=$1};1' | cut -d \  -f 2 | cut -d \/ -f 1 | head -n 1)

if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    message="Fetched IP does not look valid! Quitting"
    echo -e "$message"
    exit 1
fi

zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "Authorization: Bearer $api_token" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "Authorization: Bearer $api_token" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

echo "zone : $zone_identifier"
echo "record : $record_identifier"

if [ -z $record_identifier ]; then
  update=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/" -H "Authorization: Bearer $api_token" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"proxied\":$proxied,\"name\":\"$record_name\",\"content\":\"$ip\"}")
else
  update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "Authorization: Bearer $api_token" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"proxied\":$proxied,\"name\":\"$record_name\",\"content\":\"$ip\"}")
fi

case "$update" in
  *"\"success\":false"*)
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    echo -e "$message"
    exit 1;;
  *)
      message="IP changed to: $ip"
    echo "$message";;
esac
