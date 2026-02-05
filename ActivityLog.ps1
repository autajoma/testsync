$azSubscriptions = Get-AzSubscription -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47" -SubscriptionId  "84a75e8c-f0f3-4a49-87f1-b962c50a578f"                                                                                                  

foreach ($azSubscription in $azSubscriptions) {
  $retryCount = 0
  $validReturn = $false
  $azLogsQuery = ""

  Set-AzContext -Tenant "72f988bf-86f1-41af-91ab-2d7cd011db47" -SubscriptionName $azSubscription -WarningAction SilentlyContinue | Out-Null
  Write-Host "Setting to subscription: $($azSubscription)" -ForegroundColor White

  do {
    try {
      $azLogsQuery = Get-AzActivityLog -WarningAction SilentlyContinue -StartTime 2023-10-01T10:30 -EndTime 2023-09-14T11:30 | Where-Object { $_.Properties.Content.message -eq "Microsoft.Authorization/policies/deny/action" } 
     #if (null -eq $azLogsQuery) {
     #   throw
   # }
      $validReturn = $true
    }
    catch {
      if ($retryCount -gt 3) {
        Write-Host "Could not retrieve activity logs after 3 tries..." -ForegroundColor Red
        $validReturn = $true
      }
      else {
        Write-Host "Could not retrieve logs.... retrying in 15 seconds..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        $retryCount ++
      }
    }
  }
  while ($validReturn -eq $false)

  if ($validReturn -eq $true) {
    if (($azLogsQuery.Count -eq 0) -or ($null -eq $azLogsQuery.Count)) {
      Write-Host "DENY policies triggered: $($azLogsQuery.Count)" -ForegroundColor Green
    }
    else {
      $policyTally = $azLogsQuery.properties.content.policies | convertfrom-json
      Write-Host "DENY policies triggered: $($policyTally.Count)" -ForegroundColor Yellow
      $policyIndex = $policyTally.policyDefinitionDisplayName | Group-Object | Select-Object Name, Count
      $policyIndex | ForEach-Object {
        Write-Host "COUNT: $($_.Count) - POLICY: $($_.Name)" -ForegroundColor Yellow
      }
    }
  }
  else {
    Write-Host "Command did not execute due to an error of some sort..." -ForegroundColor Red
  }
}
