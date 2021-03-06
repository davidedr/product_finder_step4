#!/bin/bash
sudo pip3 install boto3
echo ''
echo Please enter a valid email address:
read email_address
echo Email address:$email_address
echo Please enter a valid phone number.  Example 0000000000:
read phone_number
echo Phone number:$phone_number
echo Please enter a valid IP address:
read ip_address
echo IP address:$ip_address
echo Please wait...
sudo pip install --upgrade awscli
bucket=`aws s3api list-buckets --query "Buckets[].Name" | grep s3bucket | tr -d ',' | sed -e 's/"//g' | xargs`
apigateway=`aws apigateway get-rest-apis | grep id | cut -f2- -d: | tr -d ',' | xargs`
echo $apigateway
FILE_PATH="/home/ec2-user/environment/resources/public_policy.json"
FILE_PATH_2="/home/ec2-user/environment/resources/permissions.py"
FILE_PATH_3="/home/ec2-user/environment/resources/setup.sh"
FILE_PATH_4="/home/ec2-user/environment/resources/website/config.js"
aws s3 cp --cache-control max-age=0 --content-type image/jpg ~/environment/resources/website/backdrop_camera.jpg s3://$bucket/backdrop_camera.jpg 
aws s3 cp --cache-control max-age=0 --content-type text/html ~/environment/resources/website/callback.html s3://$bucket/callback.html
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/config.js s3://$bucket/config.js
aws s3 cp --cache-control max-age=0 --content-type text/css ~/environment/resources/website/core.css s3://$bucket/core.css
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/flex_search.js s3://$bucket/flex_search.js
aws s3 cp --cache-control max-age=0 --content-type text/html ~/environment/resources/website/index.html s3://$bucket/index.html
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/jquery.js s3://$bucket/jquery.js
aws s3 cp --cache-control max-age=0 --content-type image/png ~/environment/resources/website/kiosk.png s3://$bucket/kiosk.png
aws s3 cp --cache-control max-age=0 --content-type image/png ~/environment/resources/website/kiosk_bottom.png s3://$bucket/kiosk_bottom.png
aws s3 cp --cache-control max-age=0 --content-type image/png ~/environment/resources/website/kiosk_left.png s3://$bucket/kiosk_left.png
aws s3 cp --cache-control max-age=0 --content-type image/png ~/environment/resources/website/kiosk_right.png s3://$bucket/kiosk_right.png
aws s3 cp --cache-control max-age=0 --content-type image/png ~/environment/resources/website/kiosk_top.png s3://$bucket/kiosk_top.png
aws s3 cp --cache-control max-age=0 --content-type text/css ~/environment/resources/website/main.css s3://$bucket/main.css
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/main.js s3://$bucket/main.js
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/products.js s3://$bucket/products.js
aws s3 cp --cache-control max-age=0 --content-type text/html ~/environment/resources/website/report.html s3://$bucket/report.html
aws s3 cp --cache-control max-age=0 --content-type text/css ~/environment/resources/website/reset.css s3://$bucket/reset.css
aws s3 cp --cache-control max-age=0 --content-type text/css ~/environment/resources/website/search.css s3://$bucket/search.css
aws s3 cp --cache-control max-age=0 --content-type application/javascript ~/environment/resources/website/search.js s3://$bucket/search.js
sed -i "s/<FMI_1>/$bucket/g" $FILE_PATH
sed -i "s/<FMI_2>/$ip_address/g" $FILE_PATH
#sed -i "s/<FMI_3>/$ip_address/g" $FILE_PATH
sed -i "s/<FMI>/$bucket/g" $FILE_PATH_2
python3 /home/ec2-user/environment/resources/permissions.py
POOL_ID=`aws cognito-idp list-user-pools --max-results 1 | grep Id | tr -d ':,' | sed -e 's/Id//g' | xargs`
NUMBER=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^0*//' | head --bytes 4)
if [ "$NUMBER" == "" ]; then
  NUMBER=0
fi
echo $POOL_ID
aws cognito-idp update-user-pool --user-pool-id $POOL_ID --account-recovery-setting 'RecoveryMechanisms=[{Priority=1,Name=verified_email}]' \
--admin-create-user-config 'AllowAdminCreateUserOnly=true'
aws cognito-idp admin-create-user --user-pool-id $POOL_ID \
--username ricky \
--temporary-password "!FooBar55" \
--user-attributes Name=email,Value=$email_address Name=email_verified,Value=true Name=phone_number_verified,Value=true Name=phone_number,Value="+1$phone_number" \
--desired-delivery-mediums EMAIL \
--message-action SUPPRESS
aws cognito-idp create-user-pool-domain --user-pool-id $POOL_ID --domain fancy$NUMBER-domain 
aws cognito-idp create-user-pool-client \
--user-pool-id $POOL_ID  --client-name FancyApp \
--no-generate-secret --explicit-auth-flows "ALLOW_REFRESH_TOKEN_AUTH" \
--allowed-o-auth-flows-user-pool-client \
--supported-identity-providers COGNITO \
--prevent-user-existence-errors ENABLED \
--callback-urls '["https://'$bucket'.s3-us-west-2.amazonaws.com/callback.html"]' \
--logout-urls '["https://'$bucket'.s3-us-west-2.amazonaws.com/sign-out.html"]' \
--allowed-o-auth-flows implicit \
--allowed-o-auth-scopes "openid" "profile" 
aws cognito-idp admin-set-user-password --user-pool-id $POOL_ID --username ricky --password "!FooBar55" --permanent
CLIENT_ID=`aws cognito-idp list-user-pool-clients --user-pool-id $POOL_ID | grep ClientId | cut -f2- -d: | tr -d ',' | xargs`
COG_STRING="https://fancy${NUMBER}-domain.auth.us-west-2.amazoncognito.com/login?client_id=${CLIENT_ID}\&response_type=token\&scope=openid+profile\&redirect_uri=https://${bucket}.s3-us-west-2.amazonaws.com/callback.html"
GW_STRING="https://${apigateway}.execute-api.us-west-2.amazonaws.com/test"
sed -i 's~G_COGNITO_HOSTED_URL_STR = null~G_COGNITO_HOSTED_URL_STR = \"'$COG_STRING'\"~' $FILE_PATH_4
sed -i 's~G_API_GW_URL_STR = null~G_API_GW_URL_STR = \"'$GW_STRING'\"~' $FILE_PATH_4
aws s3 cp ~/environment/resources/website/config.js s3://$bucket/config.js
echo DONE