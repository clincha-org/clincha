Start-Sleep -Seconds 1
packer build -var http_bind_address = "192.168.2.148" -var-file="credentials.pkrvars.hcl" .