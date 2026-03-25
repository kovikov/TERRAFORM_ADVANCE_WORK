# Terraform Advanced Work

This project provisions:
- A reusable VPC module (`modules/vpc`)
- Public and private subnets across 2 AZs
- Internet Gateway and route tables
- One EC2 web instance in a public subnet
- Security group for HTTP (80) and SSH (22)
- Optional auto-generated SSH key pair (when `key_name = ""`)
- Optional S3 bucket with versioning, encryption, and public access block

## Prerequisites
- Terraform installed
- AWS credentials configured (environment variables, shared profile, or SSO)
- Permissions to create VPC, subnet, route table, security group, key pair, and EC2 resources

## Quick Start
1. Copy example variables file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values.

3. Initialize Terraform:

```powershell
terraform init
```

4. Check formatting and validate:

```powershell
terraform fmt -recursive
terraform validate
```

5. Review execution plan:

```powershell
terraform plan
```

6. Apply changes:

```powershell
terraform apply
```

## Useful Commands

Show outputs:

```powershell
terraform output
```

Show S3 bucket details:

```powershell
terraform output s3_bucket_name
terraform output s3_bucket_arn
```

Read generated private key output (sensitive):

```powershell
terraform output -raw ec2_private_key_pem
```

Save key to `.pem` and restrict file access to current user:

```powershell
$keyPath = Join-Path $PWD "web-key.pem"
terraform output -raw ec2_private_key_pem | Out-File -FilePath $keyPath -Encoding ascii -NoNewline

$acl = New-Object System.Security.AccessControl.FileSecurity
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")
$acl.SetOwner([System.Security.Principal.NTAccount]$currentUser)
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule($rule)
Set-Acl -Path $keyPath -AclObject $acl
```

Connect to EC2 with OpenSSH (replace `ec2-user` if your AMI uses a different default user):

```powershell
ssh -i .\web-key.pem ec2-user@$(terraform output -raw ec2_public_ip)
```

Destroy everything:

```powershell
terraform destroy
```

## Notes
- `terraform.tfvars` is ignored by `.gitignore` to avoid committing sensitive values.
- If `key_name` is empty, Terraform creates a key pair and exposes private key material in sensitive output `ec2_private_key_pem`.
- Save private keys securely and restrict file permissions.
- If `s3_bucket_name` is empty, Terraform auto-generates a globally unique bucket-style name.
- Set `create_s3_bucket = false` to skip S3 creation.
