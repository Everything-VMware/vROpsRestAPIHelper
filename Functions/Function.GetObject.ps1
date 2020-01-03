#Lookup ResourceId from Name
Function GetObject([String]$vRopsObjName, [String]$vRopsServer, $User, $Password){

$wc = new-object system.net.WebClient
$wc.Credentials = new-object System.Net.NetworkCredential($User, $Password)
[xml]$Checker = $wc.DownloadString("https://$vRopsServer/suite-api/api/resources?name=$vRopsObjName")

$AlertReport = @()

# Check if we get more than 1 result and apply some logic
    If ([Int]$Checker.resources.pageInfo.totalCount -gt '1') {

        $DataReceivingCount = $Checker.resources.resource.resourceStatusStates.resourceStatusState.resourceStatus -eq 'DATA_RECEIVING'

            If ($DataReceivingCount.count -gt 1){
            $CheckerOutput = ''
            return $CheckerOutput 
            }
            
            Else 
            {

            ForEach ($Result in $Checker.resources.resource){

                IF ($Result.resourceStatusStates.resourceStatusState.resourceStatus -eq 'DATA_RECEIVING'){

                     $PropertiesLink = $Result.links.link | where Name -eq 'latestPropertiesOfResource'
                     $Propertiesurl = 'https://' +$vRopsServer + $PropertiesLink.href
                     [xml]$Properties = $wc.DownloadString($Propertiesurl)

                     switch($Result.resourceKey.resourceKindKey)
                        {

                        VirtualMachine {

                            $ParentvCenter = $Properties.'resource-property'.property | where name -eq 'summary|parentVcenter' | Select '#text'
                            $ParentCluster = $Properties.'resource-property'.property | where name -eq 'summary|parentCluster' | Select '#text'
                            $ParentHost = $Properties.'resource-property'.property | where name -eq 'summary|parentHost' | Select '#text'
                            $PowerState = $Properties.'resource-property'.property | where name -eq 'summary|runtime|powerState' | Select '#text'
                            $Memory = $Properties.'resource-property'.property | where name -eq 'config|hardware|memoryKB' | Select '#text'
                            $CPU = $Properties.'resource-property'.property | where name -eq 'config|hardware|numCpu' | Select '#text'
                            $INFO = $Properties.'resource-property'.property | where name -eq 'config|guestFullName' | Select '#text'

                            }


                        HostSystem {

                            $ParentvCenter = $Properties.'resource-property'.property | where name -eq 'summary|parentVcenter' | Select '#text'
                            $ParentCluster = $Properties.'resource-property'.property | where name -eq 'summary|parentCluster' | Select '#text'
                            $ParentHost = $Properties.'resource-property'.property | where name -eq 'summary|parentHost' | Select '#text'
                            $PowerState = $Properties.'resource-property'.property | where name -eq 'runtime|powerState' | Select '#text'
                            $Memory = $Properties.'resource-property'.property | where name -eq 'runtime|memoryCap' | Select '#text'
                            $CPU = $Properties.'resource-property'.property | where name -eq 'hardware|cpuInfo|numCpuPackages' | Select '#text'
                            $CPUcores = $Properties.'resource-property'.property | where name -eq 'hardware|cpuInfo|numCpuCores' | Select '#text'
                            $INFO = $Properties.'resource-property'.property | where name -eq 'cpu|cpuModel' | Select '#text'

                            }

                     }
                    $CheckerOutput = New-Object PsObject -Property @{Name=$vRopsObjName; resourceId=$Result.identifier; resourceKindKey=$Result.resourceKey.resourceKindKey; vCenter=$ParentvCenter.'#text'; Cluster=$ParentCluster.'#text'; Host=$ParentHost.'#text'; State=$PowerState.'#text'; Memory=([Int]$Memory.'#text')/1024/1024; CPU=([Int]$CPU.'#text'); CPUcores=([Int]$CPUcores.'#text'); INFO=$INFO.'#text'}

                    #GetAlerts
                     $ResID = $CheckerOutput.resourceId
                     [xml]$Alerts = $wc.DownloadString("https://$vRopsServer/suite-api/api/alerts?resourceId=$ResID")

                     ForEach ($Alert in $alerts.alerts.alert){

                        $AlertReport += New-Object PSObject -Property @{

                            Name                = $vRopsObjName
                            alertDefinitionName = $Alert.alertDefinitionName
                            alertLevel          = $Alert.alertLevel
                            status              = $Alert.status
                            controlState        = $Alert.controlState
                            startTime           = If ([int64]$Alert.startTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.startTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            cancelTime          = If ([int64]$Alert.cancelTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.cancelTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            updateTime          = If ([int64]$Alert.updateTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.updateTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            suspendUntilTime    = If ([int64]$Alert.suspendUntilTimeUTC -gt ''){([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.suspendUntilTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            alertId             = $Alert.alertId

                        }

                    }

                    Return $CheckerOutput, $AlertReport
                    
                }   
            }
    }  
 }
    else
    {

                     $PropertiesLink = $Checker.resources.resource.links.link | where Name -eq 'latestPropertiesOfResource'
                     $Propertiesurl = 'https://' +$vRopsServer + $PropertiesLink.href
                     [xml]$Properties = $wc.DownloadString($Propertiesurl)

                     switch($Checker.resources.resource.resourceKey.resourceKindKey)
                        {

                        VirtualMachine {

                            $ParentvCenter = $Properties.'resource-property'.property | where name -eq 'summary|parentVcenter' | Select '#text'
                            $ParentCluster = $Properties.'resource-property'.property | where name -eq 'summary|parentCluster' | Select '#text'
                            $ParentHost = $Properties.'resource-property'.property | where name -eq 'summary|parentHost' | Select '#text'
                            $PowerState = $Properties.'resource-property'.property | where name -eq 'summary|runtime|powerState' | Select '#text'
                            $Memory = $Properties.'resource-property'.property | where name -eq 'config|hardware|memoryKB' | Select '#text'
                            $CPU = $Properties.'resource-property'.property | where name -eq 'config|hardware|numCpu' | Select '#text'
                            $INFO = $Properties.'resource-property'.property | where name -eq 'config|guestFullName' | Select '#text'

                            }


                        HostSystem {

                            $ParentvCenter = $Properties.'resource-property'.property | where name -eq 'summary|parentVcenter' | Select '#text'
                            $ParentCluster = $Properties.'resource-property'.property | where name -eq 'summary|parentCluster' | Select '#text'
                            $ParentHost = $Properties.'resource-property'.property | where name -eq 'summary|parentHost' | Select '#text'
                            $PowerState = $Properties.'resource-property'.property | where name -eq 'runtime|powerState' | Select '#text'
                            $Memory = $Properties.'resource-property'.property | where name -eq 'runtime|memoryCap' | Select '#text'
                            $CPU = $Properties.'resource-property'.property | where name -eq 'hardware|cpuInfo|numCpuPackages' | Select '#text'
                            $CPUcores = $Properties.'resource-property'.property | where name -eq 'hardware|cpuInfo|numCpuCores' | Select '#text'
                            $INFO = $Properties.'resource-property'.property | where name -eq 'cpu|cpuModel' | Select '#text'

                            }

                     }
    
    $CheckerOutput = New-Object PsObject -Property @{Name=$vRopsObjName; resourceId=$Checker.resources.resource.identifier; resourceKindKey=$Checker.resources.resource.resourceKey.resourceKindKey; vCenter=$ParentvCenter.'#text'; Cluster=$ParentCluster.'#text'; Host=$ParentHost.'#text'; State=$PowerState.'#text'; Memory=([Int]$Memory.'#text')/1024/1024; CPU=([Int]$CPU.'#text'); CPUcores=([Int]$CPUcores.'#text'); INFO=$INFO.'#text'}

                    #GetAlerts
                     $ResID = $CheckerOutput.resourceId
                     [xml]$Alerts = $wc.DownloadString("https://$vRopsServer/suite-api/api/alerts?resourceId=$ResID")

                     ForEach ($Alert in $alerts.alerts.alert){

                        $Alertreport += New-Object PSObject -Property @{

                            Name                = $vRopsObjName
                            alertDefinitionName = $Alert.alertDefinitionName
                            alertLevel          = $Alert.alertLevel
                            status              = $Alert.status
                            controlState        = $Alert.controlState
                            startTime           = If ([int64]$Alert.startTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.startTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            cancelTime          = If ([int64]$Alert.cancelTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.cancelTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            updateTime          = If ([int64]$Alert.updateTimeUTC -gt '') {([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.updateTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            suspendUntilTime    = If ([int64]$Alert.suspendUntilTimeUTC -gt ''){([TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddMilliSeconds([int64]$Alert.suspendUntilTimeUTC))).tostring("dd/MM/yyyy HH:mm:ss")} else {}
                            alertId             = $Alert.alertId

                        }

                    }

                    Return $CheckerOutput, $AlertReport

    }
}