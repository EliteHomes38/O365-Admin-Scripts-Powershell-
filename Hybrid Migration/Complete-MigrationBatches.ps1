$BatchName = Read-Host "Enter batch name or part of the name"
Get-MigrationBatch  | where {$_.Identity -like "*$batchName*" } | Select Identity, Status -OutVariable Batches

$Q = Read-Host "Complete above batches now ? [Y] or [N]"
if ($q -eq "Y"){

    $Batches | % {[string]$id = $_.Identity; Complete-MigrationBatch -Identity $id -Confirm:$false }
    Sleep -Seconds 60

    $count = 1..100
    forEach ($item in $count){
        $Batches| % {[string]$id = $_.Identity; Get-MigrationUser -BatchId $ID | Get-MigrationUserStatistics }| FT BatchId, Identifier, SyncedItemCount, EstimatedTotalTransferCount, TotalItemsInSourceMailboxCount, PercentageComplete, *status* 
        sleep -Seconds 60
    }
}

