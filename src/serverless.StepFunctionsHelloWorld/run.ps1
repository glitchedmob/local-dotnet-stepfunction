$env:AWS_ENDPOINT_URL="http://localhost.localstack.cloud:4566"
$env:AWS_ENDPOINT_URL_S3="http://s3.localhost.localstack.cloud:4566"
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:AWS_DEFAULT_REGION="us-east-1"
#
#aws s3api create-bucket --bucket localstack-bucket 
#
dotnet lambda deploy-serverless --region $env:AWS_DEFAULT_REGION

$stateMachineArn = aws stepfunctions list-state-machines `
    --query "max_by(stateMachines[?contains(name, 'HelloWorldStepFunction')], &creationDate).stateMachineArn" `
    --output text

if ([string]::IsNullOrEmpty($stateMachineArn)) {
    Write-Error "No matching state machine found."
    exit 1
}

Write-Output "Using state machine ARN: $stateMachineArn"

$startResponse = aws stepfunctions start-execution `
    --state-machine-arn $stateMachineArn `
    --input '{"key": "value"}' | ConvertFrom-Json

$executionArn = $startResponse.executionArn
Write-Output "Started execution: $executionArn"

while ($true) {
    $describe = aws stepfunctions describe-execution --execution-arn $executionArn | ConvertFrom-Json
    $status = $describe.status
    Write-Output "Current execution status: $status"

    if ($status -eq "RUNNING") {
        Start-Sleep -Seconds 1
    }
    else {
        Write-Output "Execution finished with status: $status"
        if ($status -eq "SUCCEEDED" -and $describe.output) {
            Write-Output "Final output: $($describe.output)"
        }
        break
    }
}