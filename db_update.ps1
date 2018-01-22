add-pssnapin SqlServerCmdletSnapin100;
add-pssnapin SqlServerProviderSnapin100;

$sqltimeout = (60*60*3)
$RECIPIENTCC = "DB.Update@some.local"
$searchpath = "\\srv-fs04.some.local\DB_update$\*.upd"
$touch = "\\srv-fs04.some.local\DB_update$\lastrun"

set-content -Path $touch -Value ($null)
$files = Get-ChildItem $searchpath

foreach ($file in $files)
{
write-host  "Working with " + $file
$content=Get-Content $file
if ($content.Count -ge 3)
{
$DBNAME=$content[0]
$DBNEWNAME=$content[1]
$RECIPIENTTO=$content[2]

$MyArray1 = ("DBNAME=" + $DBNAME)
$Body = write-output "$DBNAME to $DBNEWNAME<p>"
Send-MailMessage -To $RECIPIENTTO -Cc $RECIPIENTCC -Subject "Start database copy" -SmtpServer "mail.some.local" -From db_autoupdate@some.local  -Encoding Unicode -Body $body -BodyAsHtml
Invoke-Sqlcmd -ServerInstance "SRV-SQL04" -InputFile "C:\_Script\db_update\Backup.sql" -Variable $MyArray1 -ConnectionTimeout $sqltimeout -QueryTimeout $sqltimeout
 if(!$?) {
	    Send-MailMessage -To $RECIPIENTTO -Cc $RECIPIENTCC -Subject "Database update was failed" -SmtpServer "mail.some.local" -From db_autoupdate@some.local  -Encoding Unicode -Body $error[0].Exception.Message -BodyAsHtml
         }
  else
    {
    $MyArray2 = "DBNAME=$DBNAME", "DBNEWNAME=$DBNEWNAME"
    Invoke-Sqlcmd -ServerInstance "SRV-SQL03" -InputFile "C:\_Script\db_update\Restore.sql" -Variable $MyArray2 -ConnectionTimeout $sqltimeout -QueryTimeout $sqltimeout

        if(!$?) {
 	            Send-MailMessage -To $RECIPIENTTO -Cc $RECIPIENTCC -Subject "Database restore was failed" -SmtpServer "mail.some.local" -From db_autoupdate@some.local  -Encoding Unicode -Body $error[0].Exception.Message -BodyAsHtml
                }
                 else
                {
                $Body1 = write-output "Database $DBNEWNAME was updated from $DBNAME. <p>"
                if ($error.count -ge 1) {$Body += write-output $error[0].Exception.Message}
                Send-MailMessage -To $RECIPIENTTO -Cc $RECIPIENTCC -Subject "Database update is done" -SmtpServer "mail.some.local" -From db_autoupdate@some.local  -Encoding Unicode -Body $Body1  -BodyAsHtml

                If (Test-Path ($file.FullName + ".done"))
	            { 
	            Remove-Item -path ($file.FullName + ".done") -force
            	}
                Rename-Item -path $file -newname ($file.FullName + ".done") -force
} 
} 
}
}
write-host "Nothing to do.."
