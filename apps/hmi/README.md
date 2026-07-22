HMI is an API managed by Azure API Manager which calls other backend services

They use SDS Jenkins pipeline to manage APIM config via Terraform in [hmi-apim-infrastructures](https://github.com/hmcts/hmi-apim-infrastructures). The image they build is not a service application, instead it functionally tests the API directly from the dev or stg clusters

Only dev & stg namespaces are required as targets for Jenkins
