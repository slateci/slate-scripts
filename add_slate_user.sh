#!/bin/sh

NAME=$1
GLOBUS_ID=$(uuidgen)
EMAIL=$2

ENDPOINT=$(cat ~/.slate/endpoint)
TOKEN=$(cat ~/.slate/token)

DATA='{"apiVersion":"v1alpha1","metadata":{"name":"'"$NAME"'","email":"'"$EMAIL"'","globusID":"'"$GLOBUS_ID"'","phone":"no phone","institution":"SLATE","admin":false}}'
RESULT=$(curl -s -d "${DATA}" $ENDPOINT/v1alpha3/users?token=$TOKEN)
if [ "$?" -ne 0 ]; then
        echo "Error: $RESULT"
        exit 1
fi
USER_ID=$(echo ${RESULT} | sed 's|.*"id":"\([^"]*\)".*|\1|')
USER_TOKEN=$(echo ${RESULT} | sed 's|.*"access_token":"\([^"]*\)".*|\1|')
echo "$NAME $USER_ID $USER_TOKEN" >> slate_users
echo "Created $USER_ID"

