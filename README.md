# SMB-NewGen

To enable service SMB:
```bash
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" 
```

To check the SMB service status
```bash
Get-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)"
```


To Install the OpenSSH:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Administrator\Downloads\SMB-NewGen\install-openssh.ps1"
```
