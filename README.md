# Oracle Autonomous Database + Python - Simple ORM Stack

A minimal OCI Resource Manager stack that deploys Oracle Autonomous Database with a Python-ready compute instance.

## 🎯 What This Deploys

- **Oracle Autonomous Database** (Always Free tier - 20GB, 1 OCPU)
- **Oracle Linux Instance** (Always Free tier - VM.Standard.E2.1.Micro)
- **Pre-configured Python Environment** (Oracle Instant Client + cx_Oracle)
- **Basic VCN** (10.0.0.0/16 with public subnet)

## 🚀 Quick Deployment

### 1. Create the Stack
1. **Download** all files from this repository
2. **Create ZIP** file containing: `main.tf`, `variables.tf`, `outputs.tf`, `schema.yaml`
3. **Go to OCI Console** → Developer Services → Resource Manager → Stacks
4. **Create Stack** → Upload ZIP file

### 2. Configure Variables
- **Database Admin Password**: 8+ characters (e.g., `Demo123!`)
- **SSH Public Key**: Your SSH public key for instance access

### 3. Deploy
1. **Plan** → Review resources
2. **Apply** → Deploy (takes ~3-5 minutes)

## 📋 Post-Deployment Setup

### Step 1: Get Connection Info
From stack outputs, note:
- **Instance IP**: Public IP of your compute instance
- **SSH Command**: Ready-to-use SSH command

### Step 2: Download Database Wallet
1. **Go to OCI Console** → Oracle Database → Autonomous Database
2. **Click "PythonADB"** → **DB Connection**
3. **Download Wallet** → Set any password → Save as `wallet.zip`

### Step 3: Setup Instance
```bash
# SSH to instance
ssh opc@<instance_ip>

# Upload wallet (from your local machine)
scp wallet.zip opc@<instance_ip>:

# Extract wallet on instance
mkdir wallet
unzip wallet.zip -d wallet/

# Test connection
python3 test_connect.py
```

## ✅ What's Pre-Installed

- **Oracle Instant Client 19.21** - Database connectivity
- **Python 3** - Latest version from Oracle Linux
- **cx_Oracle** - Python Oracle database driver
- **Environment Variables** - LD_LIBRARY_PATH configured
- **Test Scripts** - Ready-to-run connection tests

## 🧪 Testing the Connection

After setup, test with:
```bash
python3 test_connect.py
```

**Expected output:**
```
✅ Success: Hello Oracle!
```

If you get an error, check:
```bash
# Verify wallet files
ls -la wallet/

# Test basic Oracle client
python3 test.py
```

## 📁 File Structure

```
oracle-adb-python-stack/
├── main.tf           # Core infrastructure
├── variables.tf      # Input variables
├── outputs.tf        # Stack outputs
├── schema.yaml       # ORM UI configuration
└── README.md         # This file
```

## 🔗 Connection Details

### Database Information:
- **Name**: PYTHONADB
- **Workload**: OLTP (Transaction Processing)
- **Admin User**: ADMIN
- **Service Names**: pythonadb_high, pythonadb_medium, pythonadb_low

### Python Connection Example:
```python
import cx_Oracle

# Initialize Oracle client
cx_Oracle.init_oracle_client(lib_dir="/opt/oracle/instantclient_19_21")

# Connect to database
connection = cx_Oracle.connect(
    "ADMIN", 
    "your_password", 
    "pythonadb_high",
    config_dir="/home/opc/wallet"
)

# Execute query
cursor = connection.cursor()
cursor.execute("SELECT 'Hello Oracle!' FROM dual")
result = cursor.fetchone()
print(result[0])

# Clean up
cursor.close()
connection.close()
```

## 💰 Cost Information

### Always Free Resources:
- **ADB**: 20GB storage, 1 OCPU (free forever)
- **Compute**: VM.Standard.E2.1.Micro (free forever)
- **Network**: VCN, subnet, gateway (free)

**Total Cost**: $0/month (within Always Free limits)

## 🛠️ Troubleshooting

### Common Issues:

#### 1. SSH Connection Failed
```bash
# Check security group allows SSH (port 22)
# Verify your private key matches the public key used
```

#### 2. Python Import Error
```bash
# Check Oracle client installation
ls -la /opt/oracle/instantclient_19_21/

# Verify environment
echo $LD_LIBRARY_PATH
```

#### 3. Database Connection Failed
```bash
# Verify wallet files
ls -la wallet/
cat wallet/tnsnames.ora

# Check service name (case sensitive)
# pythonadb_high, pythonadb_medium, pythonadb_low
```

#### 4. Permission Denied
```bash
# Make sure you're user 'opc'
whoami

# Check file ownership
ls -la /home/opc/
```

## 🔧 Customization

### Change Instance Shape:
Edit `variables.tf`:
```hcl
variable "instance_shape" {
  default = "VM.Standard.E3.Flex"  # For more resources
}
```

### Use Paid ADB:
Edit `main.tf`:
```hcl
resource "oci_database_autonomous_database" "adb" {
  cpu_core_count           = 2        # More CPU
  data_storage_size_in_tbs = 1        # Use TB for paid tier
  is_free_tier             = false    # Disable free tier
  # ... other settings
}
```

## 📚 Next Steps

### Development Ideas:
1. **Build a Flask app** connecting to Oracle ADB
2. **Create data analytics** with pandas + Oracle
3. **Set up automated ETL** processes
4. **Deploy machine learning** models using Oracle data

### Additional Setup:
```bash
# Install additional Python packages
sudo pip3 install pandas flask sqlalchemy

# Set up Jupyter notebook
sudo pip3 install jupyter
jupyter notebook --ip=0.0.0.0 --no-browser
```

## 🤝 Support

### For Issues:
- **ORM Stack**: Check Terraform logs in OCI Console
- **Database**: Use OCI Support or documentation
- **Python**: Check cx_Oracle documentation
- **Instance**: SSH and check `/var/log/cloud-init.log`

### Useful Commands:
```bash
# Check cloud-init logs
sudo cat /var/log/cloud-init.log

# Check setup completion
sudo cat /var/log/oracle-setup.log

# Restart services if needed
sudo systemctl restart cloud-init
```

## 🎉 Success Criteria

You've successfully completed the setup when:
1. ✅ SSH connection works
2. ✅ `python3 test.py` shows Oracle client ready
3. ✅ `python3 test_connect.py` shows successful database connection
4. ✅ You can run your own Python scripts with Oracle connectivity

Happy coding with Oracle Autonomous Database! 🚀