# OCI Autonomous Database + Python Terraform Stack

A minimal OCI Resource Manager stack that deploys Oracle Autonomous Database with a Python-ready compute instance using the modern **python-oracledb** driver.

## 🎯 What You Get

- **Oracle Autonomous Database** (Always Free tier - 20GB, 1 OCPU)
- **Oracle Linux Instance** (Always Free tier - VM.Standard.E2.1.Micro)
- **Pre-configured Python Environment** (python-oracledb driver)
- **Basic VCN** (10.0.0.0/16 with public subnet)

## 🚀 Quick Start

### 1. Prepare Files
- Download all files from this repository
- Create ZIP file containing: `main.tf`, `variables.tf`, `outputs.tf`, `schema.yaml`

### 2. Deploy via Resource Manager
- Go to OCI Console → Developer Services → Resource Manager → Stacks
- Create Stack → Upload ZIP file
- **Database Admin Password**: 8+ characters (e.g., `Demo123!`)
- **SSH Public Key**: Your SSH public key for instance access
- Plan → Review resources
- Apply → Deploy (takes ~3-5 minutes)

### 3. Get Connection Details
From stack outputs, note:
- **Instance IP**: Public IP of your compute instance
- **SSH Command**: Ready-to-use SSH command

### 4. Download Database Wallet
- Go to OCI Console → Oracle Database → Autonomous Database
- Click "PythonADB" → DB Connection
- Download Wallet → Set any password → Save as `wallet.zip`

### 5. Connect and Test
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

## 📦 Pre-installed Software

- **Python 3** - Latest version from Oracle Linux
- **python-oracledb** - Modern Oracle database driver (successor to cx_Oracle)
- **Environment Variables** - Properly configured for database connectivity
- **Test Scripts** - Ready-to-run connection tests

After setup, test with:
```bash
python3 test_connect.py
```

Expected output:
```
✅ Success: Hello Oracle!
```

If you get an error, check:
```bash
# Verify wallet files
ls -la wallet/

# Test basic python-oracledb installation
python3 -c "import oracledb; print('python-oracledb installed successfully')"
```

## 📁 Repository Structure

```
oracle-adb-python-stack/
├── main.tf              # Core infrastructure
├── variables.tf         # Input variables
├── outputs.tf           # Stack outputs
├── schema.yaml          # ORM UI configuration
└── README.md            # This file
```

## 🗄️ Database Details

- **Name**: PYTHONADB
- **Workload**: OLTP (Transaction Processing)
- **Admin User**: ADMIN
- **Service Names**: pythonadb_high, pythonadb_medium, pythonadb_low

## 🐍 Python Connection Example

### Using python-oracledb (Thin Mode - Recommended)

```python
import oracledb

# Connect to database using wallet
connection = oracledb.connect(
    user="ADMIN",
    password="your_password",
    dsn="pythonadb_high",
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

### Using python-oracledb (Thick Mode - Optional)

For advanced Oracle Database features, you can enable Thick mode:

```python
import oracledb

# Initialize Oracle Client (for Thick mode)
oracledb.init_oracle_client()

# Connect to database
connection = oracledb.connect(
    user="ADMIN",
    password="your_password",
    dsn="pythonadb_high",
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

### Connection Without Wallet (TLS - Alternative)

For simplified deployment, you can also connect without a wallet using TLS:

```python
import oracledb

# Connect using connection string (no wallet required)
connection = oracledb.connect(
    user="ADMIN",
    password="your_password",
    dsn="(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=your-adb-host))(connect_data=(service_name=pythonadb_high))(security=(ssl_server_dn_match=yes)))"
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

- **ADB**: 20GB storage, 1 OCPU (free forever)
- **Compute**: VM.Standard.E2.1.Micro (free forever)
- **Network**: VCN, subnet, gateway (free)

**Total Cost**: $0/month (within Always Free limits)

## 🔧 Troubleshooting

### Common Issues

**SSH Connection Problems**:
```bash
# Check security group allows SSH (port 22)
# Verify your private key matches the public key used
```

**Database Connection Issues**:
```bash
# Check python-oracledb installation
python3 -c "import oracledb; print(oracledb.__version__)"

# Verify wallet files
ls -la wallet/
cat wallet/tnsnames.ora

# Check service name (case sensitive)
# pythonadb_high, pythonadb_medium, pythonadb_low

# Make sure you're user 'opc'
whoami

# Check file ownership
ls -la /home/opc/
```

### Instance Setup Logs
```bash
# Check cloud-init logs
sudo cat /var/log/cloud-init.log

# Check setup completion
sudo cat /var/log/oracle-setup.log

# Restart services if needed
sudo systemctl restart cloud-init
```

## 📈 Scaling to Production

### Modify Variables

Edit `variables.tf`:
```hcl
variable "instance_shape" {
  default = "VM.Standard.E3.Flex" # For more resources
}
```

### Upgrade Database

Edit `main.tf`:
```hcl
resource "oci_database_autonomous_database" "adb" {
  cpu_core_count = 2              # More CPU
  data_storage_size_in_tbs = 1    # Use TB for paid tier
  is_free_tier = false            # Disable free tier
  # ... other settings
}
```

## 🛠️ Use Cases

- **Flask/Django Apps**: Build web applications with enterprise-grade database backends
- **Data Analytics**: Use pandas, numpy, and other data science libraries with Oracle data
- **ETL Processes**: Develop automated data pipelines
- **Machine Learning**: Deploy ML models using Oracle as the data source

### Install Additional Packages
```bash
# Install additional Python packages
sudo pip3 install pandas flask sqlalchemy jupyter

# Set up Jupyter notebook
jupyter notebook --ip=0.0.0.0 --no-browser
```

## 🆕 Migration from cx_Oracle

If you're migrating from cx_Oracle to python-oracledb:

### Key Changes
- **Package name**: `cx_Oracle` → `oracledb`
- **Import statement**: `import cx_Oracle` → `import oracledb`
- **Initialization**: `cx_Oracle.init_oracle_client()` → `oracledb.init_oracle_client()` (only for Thick mode)
- **Default mode**: python-oracledb runs in Thin mode by default (no Oracle Client libraries required)

### Migration Example
**Old (cx_Oracle)**:
```python
import cx_Oracle
cx_Oracle.init_oracle_client(lib_dir="/opt/oracle/instantclient_19_21")
connection = cx_Oracle.connect("user", "password", "dsn")
```

**New (python-oracledb)**:
```python
import oracledb
# Thin mode (default) - no init_oracle_client() needed
connection = oracledb.connect(user="user", password="password", dsn="dsn")
```

## 📚 Additional Resources

- **ORM Stack**: Check Terraform logs in OCI Console
- **Database**: Use OCI Support or documentation
- **python-oracledb**: Check [python-oracledb documentation](https://python-oracledb.readthedocs.io/)
- **Instance**: SSH and check `/var/log/cloud-init.log`

## ✅ Success Checklist

You've successfully completed the setup when:

- ✅ SSH connection works
- ✅ `python3 -c "import oracledb"` runs without errors
- ✅ `python3 test_connect.py` shows successful database connection
- ✅ You can run your own Python scripts with Oracle connectivity

Happy coding with Oracle Autonomous Database and python-oracledb! 🚀

---

## 📝 About python-oracledb

**python-oracledb** is the modern successor to cx_Oracle, Oracle's official Python driver for Oracle Database. Key advantages:

- **Thin Mode**: Direct connection to Oracle Database without requiring Oracle Client libraries
- **Thick Mode**: Optional mode for advanced Oracle Database features
- **Enhanced Performance**: Optimized for better performance and resource usage
- **Future-Proof**: Actively maintained and updated by Oracle
- **Easy Migration**: Drop-in replacement for most cx_Oracle applications

oci limits quota list --compartment-id ocid1.compartment.oc1..aaaaaaaar5h7zop2voajayl3ww7vja7yeta664vxgyk2h7jkbf32cqm55qpq