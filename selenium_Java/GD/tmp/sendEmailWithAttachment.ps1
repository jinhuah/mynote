$File = "C:\Users\Jinhua\workspace\Saiku-UI-Tests\test-output\emailable-report.html"
$Att = new-object Net.Mail.Attachment($File)

$Msg = new-object Net.Mail.MailMessage

$Msg.From = "jinhua.huang@geniusdigital.tv"
$Msg.To.Add("jinhua.huang@geniusdigital.tv")
$Msg.To.Add("jinhua.huang@geniusdigital.tv")
$Msg.Subject = "Saiku UI automation test daily report"
$Msg.Body = "Saiku UI automation test run daily and an email will be sent after the test."
$Msg.Attachments.Add($Att)

$SMTPServer = "smtp.gmail.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("jinhua.huang@geniusdigital.tv", "nantongjh");
$SMTPClient.Send($Msg)