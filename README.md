# 🐍 Simple Oracle ADB + Python Stack

**Deploy Oracle Autonomous Database with Python in minutes using modern python-oracledb driver**

## ⚡ Quick Start

Choose your deployment mode:
- **FREE**: Always Free resources ($0/month) - Perfect for development
- **PAID**: Custom resources with auto-scaling - Perfect for production

## 🎯 What You Get

### Always Free Tier ($0/month)
- **Compute**: VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM)
- **Database**: Oracle ADB 23ai (1 CPU, 20GB storage)
- **Python**: Latest python-oracledb driver pre-installed
- **Web Access**: HTTP/HTTPS ports open for Flask apps

### Paid Tier (Variable cost)
- **Compute**: VM.Standard.E4.Flex (1-32 OCPUs, 1-512GB RAM)
- **Database**: Oracle ADB 23ai (1-128 CPUs, 20GB-384TB storage)
- **Auto-scaling**: Optional database auto-scaling
- **Production**: Full production capabilities

## 🚀 Deploy Now

### Option 1: OCI Resource Manager (Recommended)

1. **Download Files**
   ```bash
   git clone <this-repo>
   cd simple-oracle-python-stack
   ```

2. **Create Deployment Package**
   ```bash
   zip terraform-stack.zip main.tf variables.tf outputs.tf schema.yaml cloud-init.yaml
   ```

3. **Deploy via OCI Console**
   - Go to OCI Console → Developer Services → Resource Manager → Stacks
   - Create Stack → Upload `terraform-stack.zip`
   - **Required Inputs** (only 2!):
     - SSH Public Key
     - Admin Password (8+ characters)
   - **Choose Mode**: Keep "Use Always Free Resources" checked for $0 deployment
   - Apply → Deploy (takes 3-5 minutes)

### Option 2: Terraform CLI

1. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your SSH key and password
   ```

2. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📝 Configuration Examples

### Free Development Environment
```hcl
# terraform.tfvars
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
admin_password = "MySecurePass123!"
use_free_tier = true
```
**Cost**: $0/month

### Small Production Setup
```hcl
# terraform.tfvars
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
admin_password = "MySecurePass123!"
use_free_tier = false
compute_ocpus = 2
compute_memory_gb = 16
adb_cpu_cores = 2
adb_storage_gb = 1024
enable_auto_scaling = true
```
**Cost**: ~$50-100/month

### High-Performance Setup
```hcl
# terraform.tfvars
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
admin_password = "MySecurePass123!"
use_free_tier = false
compute_ocpus = 8
compute_memory_gb = 64
adb_cpu_cores = 8
adb_storage_gb = 5120
enable_auto_scaling = true
```
**Cost**: ~$200-500/month

## 🔧 Post-Deployment Setup

After deployment completes:

### 1. Connect to Your Instance
```bash
# Use the SSH command from outputs
ssh opc@<instance-ip>
```

### 2. Download Database Wallet
- Go to OCI Console → Autonomous Database
- Click your database → DB Connection
- Download Wallet → Save as `wallet.zip`

### 3. Upload and Extract Wallet
```bash
# Upload wallet to instance
scp wallet.zip opc@<instance-ip>:

# SSH to instance and extract
ssh opc@<instance-ip>
unzip wallet.zip -d wallet/
```

### 4. Test Connection
```bash
python3 test_connection.py
```

Expected output:
```
✅ Connected to Oracle Autonomous Database!
📊 Query result: Hello from Oracle ADB!
🗄️  Database: Oracle Database 23ai Enterprise Edition
```

## 🐍 Python Examples

### Basic Connection
```python
import oracledb

# Connect using python-oracledb (Thin mode - no Oracle Client needed)
connection = oracledb.connect(
    user="ADMIN",
    password="your_password",
    dsn="PYTHONDB_high",
    config_dir="/home/opc/wallet"
)

cursor = connection.cursor()
cursor.execute("SELECT 'Hello Oracle!' FROM dual")
result = cursor.fetchone()
print(result[0])

cursor.close()
connection.close()
```

### Flask Web App
```python
from flask import Flask
import oracledb

app = Flask(__name__)

@app.route('/')
def index():
    connection = oracledb.connect(
        user="ADMIN",
        password="your_password",
        dsn="PYTHONDB_high",
        config_dir="/home/opc/wallet"
    )
    # Your app logic here
    return "Hello from Oracle ADB!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Access your web app**: `http://<instance-ip>:5000`

## 📦 Pre-installed Scripts

The deployment includes ready-to-use Python scripts:

| Script | Purpose | Usage |
|--------|---------|-------|
| `test_connection.py` | Test database connectivity | `python3 test_connection.py` |
| `flask_app.py` | Web application example | `python3 flask_app.py` |
| `connection_example.py` | Basic connection template | `python3 connection_example.py` |

## 🔗 Database Connection Details

### Connection Strings
- **High Performance**: `PYTHONDB_high`
- **Balanced**: `PYTHONDB_medium`
- **Low Cost**: `PYTHONDB_low`

### Credentials
- **User**: `ADMIN`
- **Password**: The password you provided during deployment
- **Wallet**: `/home/opc/wallet/`

## 🛠️ Customization Options

### Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ssh_public_key` | SSH public key for access | - | ✅ |
| `admin_password` | Database admin password | - | ✅ |
| `use_free_tier` | Use Always Free resources | `true` | ❌ |
| `project_name` | Resource name prefix | `python-oracle` | ❌ |
| `database_name` | Database name | `PYTHONDB` | ❌ |

### Paid Tier Options (when `use_free_tier = false`)

| Variable | Description | Default | Range |
|----------|-------------|---------|-------|
| `compute_ocpus` | Compute OCPUs | `2` | 1-32 |
| `compute_memory_gb` | Compute memory (GB) | `16` | 1-512 |
| `adb_cpu_cores` | Database CPU cores | `2` | 1-128 |
| `adb_storage_gb` | Database storage (GB) | `1024` | 20-393,216 |
| `enable_auto_scaling` | Database auto-scaling | `false` | true/false |

## 🔒 Security Features

- **Network**: VCN with public subnet and security lists
- **Access**: SSH key-based authentication
- **Database**: Wallet-based mTLS encryption
- **Firewall**: Only necessary ports open (22, 80, 443, 5000)

## 📊 Cost Comparison

| Deployment Mode | Monthly Cost | Use Case |
|----------------|--------------|----------|
| **Always Free** | $0 | Development, learning, small projects |
| **Small Paid** | ~$50-100 | Small production apps, startups |
| **Medium Paid** | ~$100-300 | Growing applications |
| **Large Paid** | ~$300+ | Enterprise applications |

*Costs are estimates and may vary by region and usage*

## 🆘 Troubleshooting

### Common Issues

**Connection Failed**
```bash
# Check wallet files
ls -la wallet/
# Should show: cwallet.sso, ewallet.p12, tnsnames.ora, etc.

# Verify python-oracledb installation
python3 -c "import oracledb; print(oracledb.__version__)"
```

**SSH Access Issues**
```bash
# Check security groups allow SSH (port 22)
# Verify your private key matches the public key used
# Ensure instance has public IP assigned
```

**Web App Not Accessible**
```bash
# Check if Flask is running
python3 flask_app.py

# Test locally first
curl http://localhost:5000

# Check firewall allows port 5000
```

### Log Files
```bash
# Setup logs
sudo cat /var/log/setup.log

# Cloud-init logs  
sudo cat /var/log/cloud-init.log

# System logs
sudo journalctl -u cloud-init
```

## 🔄 Migration from cx_Oracle

If you're migrating from cx_Oracle to python-oracledb:

### Key Changes
```python
# Old (cx_Oracle)
import cx_Oracle
cx_Oracle.init_oracle_client()
connection = cx_Oracle.connect("user/password@dsn")

# New (python-oracledb)
import oracledb
connection = oracledb.connect(user="user", password="password", dsn="dsn")
```

### Benefits of python-oracledb
- **No Oracle Client**: Thin mode works without Oracle Client libraries
- **Better Performance**: Optimized for cloud environments
- **Modern API**: Cleaner, more pythonic interface
- **Active Development**: Latest features and security updates

## 📚 Resources

### Documentation
- [python-oracledb Documentation](https://python-oracledb.readthedocs.io/)
- [Oracle Autonomous Database](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [OCI Always Free](https://www.oracle.com/cloud/free/)

### Tutorials
- [Python Database Programming](https://python-oracledb.readthedocs.io/en/latest/user_guide/index.html)
- [Flask Web Development](https://flask.palletsprojects.com/)
- [Oracle SQL Tutorial](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlqr/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both free and paid tiers
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆚 Version History

- **v1.0**: Simple stack with FREE/PAID toggle
- **v1.1**: Added Flask web app example
- **v1.2**: Enhanced documentation and troubleshooting

---

## 🎯 Quick Summary

**Perfect for**:
- 🎓 Learning Oracle Database with Python
- 🚀 Rapid prototyping and development
- 💼 Small to medium production applications
- 🔬 Data analysis and visualization projects

**Key Features**:
- ✅ **2-minute setup** with minimal configuration
- ✅ **$0 cost option** with Always Free resources
- ✅ **Modern python-oracledb** driver
- ✅ **Production ready** scaling options
- ✅ **Pre-built examples** and documentation

**Get started now**: Download, configure 2 variables, deploy, and start coding with Oracle Database in Python! 🚀