$EmailFrom = “jinhua.huang@geniusdigital.tv”
$EmailTo = “jinhua.huang@geniusdigital.tv”
$Subject = “The subject of your email”
$Body = “What do you want your email to say”
$SMTPServer = “smtp.gmail.com”
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential(“jinhua.huang”, “nantongjh”);
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)