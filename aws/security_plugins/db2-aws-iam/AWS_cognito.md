# AWS Cognito User Pool

This document lists the steps to setup Cognito user pool, users, groups and token retrieval.

## Create user pool
1. Go to AWS Cognito console
2. Click on “Create user pool”
3. Select “User name” as cognito user pool sign-in options
4. Tick the User name requirements as per need and click on “Next”
5. Select “No MFA” and click on “Next”
6. Uncheck Enable self-registration and click on “Next”
7. Select “Send email with Cognito” as Email provider and click on “Next”
8. Enter any user pool name ex. DB2UserPool
9. Check the “Use the Cognito Hosted UI” option
10. Enter any  cognito domain
11. Select App type as Public client
12. Enter any App client name
13. Enter http://localhost as call back URL
14. Select all the authentication flows under Advanced app client settings
15. Select  only “Implicit grant” in OAuth 2.0 grant types and click on “Next”
16. Click on “Create user pool” 

## Create a user in user pool
1. Go to AWS Cognito console
2. Click on the user pool name to go to the next page
3. Under “Users” tab, click on “Create user” button
4. Enter the User name
5. Enter password for the User name
6. Click on “Create user" to create the user
7. Run below command to confirm the user, replace <userpoolid> with the user pool id and <password> with the new user password
   
   aws cognito-idp admin-set-user-password   --user-pool-id <userpoolid>  --username <username>   --password <password>   --permanent 

 Ex: 
```shell 
 aws cognito-idp admin-set-user-password   --user-pool-id us-east-1_DiDR8M202  --username test1   --password *U7y6t5r   --permanent
```

8. Verify that user’s confirmation status is “confirmed” in AWS cognito console


## Create a group in user pool
1. Go to AWS Cognito console and go to User pools
2. Click on the user pool name to go to the next page
3. Under “Groups” tab, click on “Create group” button
4. Enter group name. This name should be same as that of Db2 group names.
5. Click on “Create group” to create the group
 
## Map a user to a group in user pool
1. Go to AWS Cognito console and go to User pools
2. Click on the user pool name to go to the next page
3. Under “Groups” tab, click on group name to which user needs to be mapped
4. Click on “Add user to group”
5. Select the user and click on “Add" 

## Create a lambda function
 1. Go to AWS Lambda console
 2. Click on “Create function”
 3. Enter Function name as “generateToken”
 4. Select Runtime as Python 3.11 or above
 5. Click on “Create function” button
 6. Copy & paste the code from “generateToken.py” file or from below to the lambda code editor
```shell
import boto3
import base64
import json
import os

def lambda_handler(event, context):
    headers = event['headers']
    auth_header = headers.get('authorization')
    base64_string = auth_header.replace("Basic ", "")
    decoded_bytes = base64.b64decode(base64_string)
    decoded_string = decoded_bytes.decode('utf-8')
    username, password = decoded_string.split(":")
    
    # Initialize the AWS Cognito Identity Provider client
    cognito_client = boto3.client('cognito-idp')

    #client_id = '7lhf17juio0frr2vme38qpnsob'
    user_pool_id = os.environ["USER_POOL_ID"]
    client_id = os.environ["CLIENT_ID"]

    # Create a dictionary with the authentication parameters
    auth_params = {
        'USERNAME': username,
        'PASSWORD': password
   #     'SECRET_HASH': 'your-secret-hash'  # If you have a secret hash configured
    }

    # Perform AdminInitiateAuth to initiate authentication
    response = cognito_client.admin_initiate_auth(
        UserPoolId=user_pool_id,
        ClientId=client_id,
        AuthFlow='ADMIN_USER_PASSWORD_AUTH',  # Use ADMIN_NO_SRP_AUTH for admin-initiated auth
        AuthParameters=auth_params
    )
    return response
```
 7. Click on “Deploy” button to deploy the changes
 8. Click on “Configuration” and under Environment variables, click on “Edit”
 9. Click on “Add environment variable” and below environment variables
 
	  Key: CLIENT_ID, Value: \<CognitoUserPoolClientID\>
 
	  Key: USER_POOL_ID, Value: \<CognitoUserID\>
 
   (Replace \<CognitoUserPoolClientID\> and \<CognitoUserID\> with the actual values)
 
10. Click on Save to persist the changes
11. Click on “Configuration” and then click on "Permissions"
12. Click on link under the "Role name"
13. Click on "Add permissions" and select "Create inline policy"
14. Select "JSON" policy editor
15. Copy the below polices and paste into the JSON policy editor by replacing the existing policy. Replace {USERPOOL_ARN) with the user pool arn value
```shell
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cognito-idp:AdminInitiateAuth"
            ],
            "Resource": "{USERPOOL_ARN}"
        }
    ]
}
```	
16. Click on "Next"
17. Enter any policy name. ex. db2-lambda-cognito-policy
18. Click on "Create policy" to create the policy	
 
 ## Create an API gateway
 1. Go to AWS API gateway console
 2. Click on “Create API” 
 3. For HTTP API, Click on “Build” button and then click on “Add integration" 
 4. Choose “Lambda” from the integrations drop down, Select AWS region and Choose a lambda function from Lambda function drop down  
 5. Enter API name as “getToken” and Click on “Next” 
 6. Select method as “GET", Enter resource path as “/token” and Click on “Next” 
 7. Leave Stage name as $default and leave Auth-deploy as On and Click on “Next” 
 8. Click on “Create” to create API gateway 
 9. Click on API name under API Gateway -> APIs 
 10. Click on “API: {API name}...” on the left menu and copy the invoke URL to a text editor 
 11. Append “/token” to the Invoke IRL such as “{InvokeURL}/token” 
 12. To get the Cognito user pool JWT tokens, call the API gateway URL as
 
 curl -u '{CognitoUserName}:{CognitoUserPassword}' “{InvokeURL}/token” 

Ex. 
 ```shell
	curl -u 'test1@test.com:1234567890' https://1yq9tq9ojk.execute-api.us-east-1.amazonaws.com/token 
 ```
 
 # To generate JWT using AWS cognito Hosted UI
 1. Go to AWS Cognito console and then go to User pools
 2. Click on the user pool name to go to the next page 
 3. Click on App integration tab  
 4. Click on App client name under App clients and analytics 
 5. Under Hosted UI section, click on View Hosted UI 
 6. Enter Cognito user name and password to login 
 7. Extract the access token from the redirected URL
```shell 
http://localhost/#access_token=eyJraWQiOiIwVGp4dUdVYVVxd0IyUitzVlZnMno1VWxISkIyZERNazh3UkIxTU14WjlvPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIzYjI4ZjBhYS0zODc2LTQxNTktODNlOS01ODMzMmMzNzQ1ODIiLCJjb2duaXRvOmdyb3VwcyI6WyJEQjJBRE1JTiJdLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9EaURSOE0yMDIiLCJ2ZXJzaW9uIjoyLCJjbGllbnRfaWQiOiIxbmptcjJ2cDhkaXBiMWhuZTBhMHZydjV0ayIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoicGhvbmUgb3BlbmlkIGVtYWlsIiwiYXV0aF90aW1lIjoxNjk4NDA3NjI3LCJleHAiOjE2OTg0MTEyMjcsImlhdCI6MTY5ODQwNzYyNywianRpIjoiNDIzZmVkYTEtOTExMS00ZjlkLTgyMDUtNTgwZTRmM2MyYjI4IiwidXNlcm5hbWUiOiJ0ZXN0MSJ9.E3Kjmy0UIxWtAucxAtnGxVPJ7sTc2zKleRhoA16uMDst0YjLDM9hFuPyVYgvUmx4-W1SYWjpfcrzDNPd5_XSY6bqBGq1VbuGXcC3JO8ZXP_xdojf_4AjUFgAj-xzYPquzGJ2RHgzN5HM3Adv11lrNPynaug7FnbpNz-9bWcRcUOMzWoRd6vC0lqPe1ZY-sNEw8RL8ytqMcZfQTJg7cYE8-ZYoqJ3Yiq2dnZyBI7tIV1ewXmJOni1aPQJrrXB9PCnHK_1hEYzXiKZf4sPBkqihZV9nGCx-nMuGqVR3dAQYT6x8_c5wi2E64-8UWXYmmMgmLjZBMWRigWhT-dlL03EAg&id_token=eyJraWQiOiJOQ1FrNkxvTmpUN3lEYkVLN1ArUEkyVEhZVHdwNlpNT1FPSm9MU24wcXVFPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiaGoyd0pzTEdRdno5UkQ3dG81REdEdyIsInN1YiI6IjNiMjhmMGFhLTM4NzYtNDE1OS04M2U5LTU4MzMyYzM3NDU4MiIsImF1ZCI6IjFuam1yMnZwOGRpcGIxaG5lMGEwdnJ2NXRrIiwiY29nbml0bzpncm91cHMiOlsiREIyQURNSU4iXSwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE2OTg0MDc2MjcsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX0RpRFI4TTIwMiIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0MSIsImV4cCI6MTY5ODQxMTIyNywiaWF0IjoxNjk4NDA3NjI3LCJqdGkiOiI1MjYwNjMwOC1lMDIyLTRjMGMtYTc0NS02N2Q5NjIxM2NkNWMifQ.Lz2JLxk7tGnuos8x3_CWQ97Vznh0oSHbaQX-8ZKxXI2JE0fHhruIV69VBWiw5RS8RrUdDsWlu_4Ab02rTWo8VY1FG4VFJsImVOOapUlP3RGwwMM829-bjXhSTAO4PAd9-e6lxBkLNJ2-Y8SGALBETJblIQUHT77X5teYWVUd8I2gfrQ5ma5Kjzm7InXECJV7-h5GfjxqBrXtawfBKVI3dp87ZmiRtSOc_ERd_HIS90ybAULpD4SExzypAgxW8UpMf4cv18jKN5t06p3Er8lW_Qj1hPcNm_7-lXlCQTHnKIxNfP--yil027KMLqytF5g_ihCyiOtqWn4MWSXG6ARMQw&token_type=Bearer&expires_in=3600
``` 


# To generate JWT using API Gateway
 
To get the Cognito user pool JWT tokens, call the API gateway URL as: 
curl -u '{CognitoUserName}:{CognitoUserPassword}' “{InvokeURL}/token” 

Ex.
```shell 
curl -u 'test1@test.com:1234567890' https://1yq9tq9ojk.execute-api.us-east-1.amazonaws.com/token
``` 
Result:
```shell
{
   "ResponseMetadata" : {
      "RequestId" : "e4d3f251-a4ac-4963-8222-e555ef84097c",
      "HTTPHeaders" : {
         "date" : "Tue, 31 Oct 2023 08:44:24 GMT",
         "content-type" : "application/x-amz-json-1.1",
         "connection" : "keep-alive",
         "x-amzn-requestid" : "e4d3f251-a4ac-4963-8222-e555ef84097c",
         "content-length" : "4302"
      },
      "RetryAttempts" : 0,
      "HTTPStatusCode" : 200
   },
   "ChallengeParameters" : {},
   "AuthenticationResult" : {
      "IdToken" : "eyJraWQiOiJROGoxOFZqd1wvZis0QU5DVHhVa2labXk5c3poVkNpSUlqdW5KdkZtY2NGMD0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI5NDU4MzQ4OC00MDgxLTcwNjYtN2U5NC1jM2IyMjk5ZWY1ZTEiLCJjb2duaXRvOmdyb3VwcyI6WyJzeXNhZG1pbiIsImJsdWVhZG1pbiJdLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9mbXlOdW1rMEwiLCJjb2duaXRvOnVzZXJuYW1lIjoiOTQ1ODM0ODgtNDA4MS03MDY2LTdlOTQtYzNiMjI5OWVmNWUxIiwib3JpZ2luX2p0aSI6IjM4NTliNmMwLTdlZDgtNDliZi04NmY3LTA0Zjg1YTM0YmIzZiIsImNvZ25pdG86cm9sZXMiOlsiYXJuOmF3czppYW06OjQ0Mjk1MjYzNzM3MTpyb2xlXC9yZHNyb2xlX2Zvcl9lYzIiLCJhcm46YXdzOmlhbTo6NDQyOTUyNjM3MzcxOnJvbGVcL3Jkc3JvbGUiXSwiYXVkIjoiN2xoZjE3anVpbzBmcnIydm1lMzhxcG5zb2IiLCJldmVudF9pZCI6ImU0ZDNmMjUxLWE0YWMtNDk2My04MjIyLWU1NTVlZjg0MDk3YyIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNjk4NzQxODY0LCJleHAiOjE2OTg3NDU0NjQsImlhdCI6MTY5ODc0MTg2NCwianRpIjoiOWVmYTg1YWUtZTVhNS00YzIwLWFiYTktOTI1YjAxYTJmN2RmIiwiZW1haWwiOiJ0ZXN0MUB0ZXN0LmNvbSJ9.MQE04hRYHthQdvfi_mGIZ2-xQOibfc9nGIQ-k6NF_qTc7FpurLBtk_Cprb4Rrm-UEmMvsPwupB9_7RcyTTNgFxi909YitiVryqszq9iiGc0txdutrSuV-d4NSL-p1md-KlUMSQX3VLSdvybWnMVl2tIQmSOLMereYRdAueFcLyi7eCC2D7D7lEh8vqukWkeewVPJEez3qeDedzZB3iDARmh7NvavKPio3awK3AbBVzqSYpFd7uYn_7g4O1eUPymJwlvx81n6n-uUpPE7DMkWa7RiimHU6lq934K0HmachYniWJrTrBEzn24Tkb6Hx5kPXdZzmAGkdTA6oWcN1fxuVQ",
      "RefreshToken" : "eyJjdHkiOiJKV1QiLCJlbmMiOiJBMjU2R0NNIiwiYWxnIjoiUlNBLU9BRVAifQ.cR8uHz6No78KaEOXEUNmEa8DeovIVnoLiPHt8SBvf_iHkkfNRzNwD1mRXqvgfFIWZpRkDe-ob1cz_r8Ss_HGvs0OLMjNXCi6rzvb_ba2RTuwvBpphMR9hDwrMK6-XYdCC4PSyXpcp26obmFAYPU44ADl8UXDaSHZxi4-qjxcOsoz8coVcwglIIqYgfxK225Nh2idyglfGN94QRclmpS14QXWyDKkSN-P4B7IKMyRaCtTIYodggbxgu7DEfu1hbkREjYT4A0QD2eBeeRv7EJGjNtED2UvDjDwgs1YPcUdUq6hZvHATUgnJhwTR4UuDG3YufQ2_oqwj5owa_elWlot-Q.mkrs4TvKRsm7cSjl.K0GoU6m4cJXBfS2jDbX0UYEDUc0NluzPPdvc7yfU4vpWru8DaZE5DhshsX766OWKbHj9kAxytcXYmZIVushEKvaRCZXdVHj-3KGF8WP_bMWUuKKzqWYuKYTe0mSQ6a_obm7zY0iosk3L0cQa0EVA0qL8MLB_dJT6jZn_muPfYOKUfByIrOFGoVbir4SALuiQZAZviTNmOqyrutMvYwfuEbZJ2xGyywr_Waddzp_N0sMYsifLmr_oJ4p_wGdC4XPVo6OnHaKV1b0oEZvvtfScjjoRYDDUMJZIKMNanKWcQPVzEJ_pS9R42ImMC88smdYG6ZX_08WmymcWqwTtDDBz0iU8goE9_hUYPlNv_lPrVR6p-hyjstVW4FhreVt__kjHqo7YcmWPvwRz10C3QPBw2RRjxlge9XGwPbpF6lFqZF1LO3JXF5QglxJZpihHer0OwTQGRUbbdav5WWvnLS6JXRDNmoP5dYQN2Re0sPJr9hiwsmGzG291Q1yeI4osA4MnSrDCeGS4oVyelJWow4nhpV885xG2eneg9PQZYmvX2DyPPiwtzLX-MCE5Br72p8QeDDvbYMjMfYwQs8e-zVIy8YSNUsDkAq2jHcUbw-FCEfHLA53INiZPE37CjrluW7S2JPXHdP-1geuRgPSjJ7OANBFD2PFqILtQ-_GVQSk2A-yhJF78mk37tW7TfBihyZI_OGHWcoaGOxbFjys5GrPdxZLbRn73IrqcMo-yEbiRYVDM0ArPgdP0wns-wGTcBg47SwZ8LVkDaGesHWzX8CF74FIUM-pfedOFD89jLm1rrdUHsGMh9rsKlblD_cOXP4_FifUXWwH4fQ-dXVz1bM_u_JMyo1vW57Gb57WN_A4nozIrS2NDH6svoWaI7Hk6vSog9JJDo8gsPJgavpJdIumWqJIEHPeA0I_OgdKY5DRDXjDdgy8I8XF6ncr8ranguzDnEOovHrzqwNGeS9fRhTSQZaHV8_Rb4_ppnL2OkAQEmVNewuWitXKqGaPc6t39pg2Ec3TGu_pYtp2P8Oy3NYZMOjkZIKfPoN39RaDwW-O5VwwMaEUFYEy0nMOFr_ecCF1qu1jY81eWsd-tg67iRM9bs1mc66F7-0KOgJfWgnnjxcga0f1a5-pgfZZuTeNPkNRSNcwJcapdkOQgTSS4C9Mw3LLdTUvVygJqrDvLRaqaSO5b3nm-8aStki64I6Cs5WUuP-8HI0x2EXusWM3c_UQNePnRgLQ0uW9FxQdGP5nLqH_EMU0zy3EFEwGv-93tR5ITRZgiOZArwjsFfJFyDwH9xZc3JOqcKCpqPpxrqnzxcGh6ooGxBAOgD0r-oHo.k60SnYB8FWs6zluKOIRufg",
      "AccessToken" : "eyJraWQiOiJHUFljVVEyUGQxT2JJVUlLWEVVR1NQbVhcLzVJU0NUZFY3OEs2TjJXVFdoUT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI5NDU4MzQ4OC00MDgxLTcwNjYtN2U5NC1jM2IyMjk5ZWY1ZTEiLCJjb2duaXRvOmdyb3VwcyI6WyJzeXNhZG1pbiIsImJsdWVhZG1pbiJdLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9mbXlOdW1rMEwiLCJjbGllbnRfaWQiOiI3bGhmMTdqdWlvMGZycjJ2bWUzOHFwbnNvYiIsIm9yaWdpbl9qdGkiOiIzODU5YjZjMC03ZWQ4LTQ5YmYtODZmNy0wNGY4NWEzNGJiM2YiLCJldmVudF9pZCI6ImU0ZDNmMjUxLWE0YWMtNDk2My04MjIyLWU1NTVlZjg0MDk3YyIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE2OTg3NDE4NjQsImV4cCI6MTY5ODc0NTQ2NCwiaWF0IjoxNjk4NzQxODY0LCJqdGkiOiI0ZmFkYzkxNC05OGE5LTQxNzEtODIxMy1jNjFmYzU0ZTZmMDkiLCJ1c2VybmFtZSI6Ijk0NTgzNDg4LTQwODEtNzA2Ni03ZTk0LWMzYjIyOTllZjVlMSJ9.acEfiz0SB0GVDNR_7bmzjtqeN3XzRmGp7BBMU56ia9iDx6CGnEXOnPf9rFn7njGvZOhG-qjCGZHSTXERUv1DlCUJw_hJDhRnFSM-h6PjpBzGXo3JGDqY31j3hrtsBY9hQaYch1ZTvcPrElW0MBlZPdkXH826XK5cTNEKnZgzcMAPEYIQg4TNg_Sds47xg6VbSltA6iExeVjT7SOAc-5udif5wQzfNLTbVxxbW9s9WWC2hSiPhL2wvQbqMmh66DTRxCJFgy6utThy1APXW2cd7TDmpPoqXlmmfBK3OX0jBOzlwKNh5oRsUZHJpdpM09adCUwhes6dWq3Y-n9hDKnY5Q",
      "ExpiresIn" : 3600,
      "TokenType" : "Bearer"
   }
}
	
```	

