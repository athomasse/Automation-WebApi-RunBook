#
# Automation API Login
# Use API key, Automation Username en Password
#
Function Login-Automation()
{

    param($api_uri, $api_username, $api_password, $api_key)

    $api_login_header = @{ Authorization = $api_key }
    $api_login_body = "{userName : '$api_username', password : '$api_password'}"

    $login_token = Invoke-RestMethod -Uri "$api_uri/Auth/Login" -Method Post -ContentType "application/json"  -Headers $api_login_header -Body $api_login_body

    return $login_token.token
}

#
# Get Automation Agent based on NetBios name
#
Function Get-Agent()
{
    param($token_id, $agent_name)

    $authorization_header = @{ Authorization = $token_id }

    # search options
    $pagenumber = 1
    $pagesize = 1
    $orderAsc = "true"
    $search_param = "criteria.pageNumber=$pagenumber&criteria.pageSize=$pagesize&criteria.freeTextFilter=$agent_name&criteria.orderAsc=$orderAsc"

    $agent_list = Invoke-RestMethod -Uri "$api_uri/Agents/Search?$search_param" -Method Get -Headers $authorization_header

    return $agent_list.result
}

#
# Get Automation runbok to set parameters
#
Function Get-Runbook()
{
    param($token_id, $runbook_guid)

    $authorization_header = @{ Authorization = $token_id }
    $job = Invoke-RestMethod -Uri "$api_uri/Schedule/Create/$runbook_guid`?type=Runbook" -Method Get -Headers $authorization_header

    return $job
}

#
# Start Automation Runbook
#
Function Invoke-Runbook()
{
    param($token_id, $request_body)

    $authorization_header = @{ Authorization = $token_id }
    $invoke_job = Invoke-RestMethod -Uri "$api_uri/Schedule/Schedule" -ContentType "application/json" -Method Post -Headers $authorization_header -Body $request_body

    return $invoke_job
}


#
# Global Ivanti Automation API variable
#
$api_base_uri = '<Management portal IP or HOSTNAME>'
# Lab uses http not https
$api_uri = "http://$api_base_uri/Automation/API"
$api_key = "<API KEY>"
$api_username = "<ADMIN USER>"
$api_password = "<ADMIN PASS>"

#
# Request information
#
$automation_agent = $env:COMPUTERNAME
$runbook_guid = "{A83F11F8-9D5D-4278-B934-39715F379E0E}"


#
# API Authentication
#
$token_id = Login-Automation $api_uri $api_username $api_password $api_key


#
# Automation json objects
#
$task_object = Get-Runbook $token_id $runbook_guid
$agent_object = Get-Agent $token_id $automation_agent

# An agent must be found
if ( $agent_object -eq $null )
{
    throw "No Ivanti Automation Agent has been found with the name $automation_agent"
}

#
# Parameter values for JSON request
#
$param_RunBookWho_value = New-Object psobject -Property @{value = $automation_agent }

#
# Set the $param_RunBookWho_value as a Runbook parameter Value
#
($task_object.parameters | where { $_.name -eq 'RunBookWho' }).textValue = $param_RunBookWho_value

# Schedule information for an immediately execution
$param_schedule_value = New-Object psobject -Property @{scheduleTime = $scheduled_string
    Type                                                             = "Immediate"
    useLocalAgentTime                                                = 'true'
}

# Set the Runbook to run immediately
$task_object.when = $param_schedule_value
$task_object.scheduleInParallel = 'True'

# convert task PS Object to JSON
$task_json = $task_object | ConvertTo-Json -Depth 5


# Automation Runbook inplannen
# Taak id wordt teruggegeven
$task_id = invoke-Runbook $token_id $task_json
