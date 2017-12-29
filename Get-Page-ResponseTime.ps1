param($URL, $Times)
$i = 0
While ($i -lt $Times)
{$Request = New-Object System.Net.WebClient
$Request.UseDefaultCredentials = $true
$Start = Get-Date
$PageRequest = $Request.DownloadString($URL)
$TimeTaken = ((Get-Date) - $Start).TotalMilliseconds 
$Request.Dispose()
Write-Host Request $i took $TimeTaken ms -ForegroundColor Green
$i ++}