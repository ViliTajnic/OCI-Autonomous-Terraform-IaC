# Oracle Autonomous Database + Python - OCI Resource Manager Stack

This OCI Resource Manager (ORM) Stack deploys Oracle Autonomous Database with an Oracle Linux compute instance pre-configured for Python connectivity.

## 🎯 What This Stack Deploys

- **Oracle Autonomous Database (ATP)** - Fully managed Oracle database
- **Oracle Linux Compute Instance** - Pre-configured with Python environment
- **Virtual Cloud Network (VCN)** - Complete networking infrastructure
- **Auto-Configuration** - Wallet, environment, and test scripts ready

## 📦 Pre-Configured Components

- ✅ **Oracle Instant Client 19.21** - Database connectivity
- ✅ **Python 3 + cx_Oracle** - Python database driver
- ✅ **Database Wallet** - Auto-downloaded and configured
- ✅ **Environment Variables** - TNS_ADMIN, ORACLE_HOME, LD_LIBRARY_PATH
- ✅ **Test Scripts** - Connection validation and samples
- ✅ **Documentation** - On-instance setup guide

## 🚀 Quick Deployment

### 1. Upload to OCI Resource Manager

1. **Download/Clone** this repository
2. **Create ZIP** of all files:
   ```bash
   zip -r oracle-adb-python-stack.zip . -x "*.git*"
   ```
3. **Go to OCI Console** → Developer Services → Resource Manager → Stacks
4. **Create Stack** → Upload ZIP file
5. **Configure variables** through the web form
6. **Apply** to deploy

### 2. Required Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| **adb_admin_password** | Database admin password | `Demo123!` |
| **ssh_public_key** | SSH public key for compute access | `ssh-rsa AAAA...` |
| **adb_display_name** | Database display name | `PythonADB` |
| **instance_display_name** | Compute instance name | `PythonHost` |
| **is_free_tier** | Use Always Free tier (⚠️ max 2 per tenancy) | `false` (recommended) |

### 3. Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| **adb_cpu_core_count** | 1 | CPU cores (1-128) |
| **adb_data_storage_size_in_tbs** | 1 | Storage in TB (1-384) |
| **is_free_tier** | false | Use Always Free tier |
| **instance_shape** | VM.Standard.E2.1.Micro | Compute shape |
| **vcn_cidr_block** | 10.0.0.0/16 | VCN CIDR block |

## 🔗 Post-Deployment Access

### 1. Connect to Compute Instance
```bash
# Get public IP from stack outputs
ssh -i <private_key_file> opc@<public_ip>

# Switch to oracle user (pre-configured)
sudo su - oracle
```

### 2. Test Database Connection
```bash
# Run the auto-generated test script
python3 test_connection.py

# View setup documentation
cat README.md

# Check environment
source scripts/setup_env.sh
```

### 3. Start Development
```bash
# Environment is ready for Python development
python3 -c "import cx_Oracle; print('cx_Oracle version:', cx_Oracle.version)"

# Wallet is pre-configured
ls -la wallet/
echo $TNS_ADMIN
```

## 🐍 Python Development

### Basic Connection Example
```python
import cx_Oracle

# Initialize Oracle client
cx_Oracle.init_oracle_client(config_dir="/home/oracle/wallet")

# Create connection
dsn = cx_Oracle.makedsn(
    host=None,
    port=None,
    service_name="PYTHONADB_HIGH",  # Replace with your DB name
    config_dir="/home/oracle/wallet"
)

connection = cx_Oracle.connect(
    user="ADMIN",
    password="your_admin_password",
    dsn=dsn
)

# Execute query
cursor = connection.cursor()
cursor.execute("SELECT 'Hello Oracle ADB!' FROM dual")
result = cursor.fetchone()
print(result[0])

cursor.close()
connection.close()
```

### Service Levels Available
- **HIGH** - Maximum performance, dedicated resources
- **MEDIUM** - Balanced performance and cost
- **LOW** - Shared resources, cost-effective  
- **TP** - Transaction processing optimized
- **TPURGENT** - Highest priority processing

## 📋 Stack Outputs

After deployment, the stack provides:

- **autonomous_database_id** - Database OCID
- **database_connection_info** - Connection details and service levels
- **adb_service_console_url** - Database management console
- **compute_instance_public_ip** - Instance public IP
- **ssh_connection_command** - Ready-to-use SSH command
- **python_test_command** - Command to test connectivity
- **wallet_password** - Auto-generated wallet password (sensitive)
- **deployment_summary** - Complete setup summary

## 🔧 Pre-Installed Tools & Scripts

### On the Compute Instance:
```
/home/oracle/
├── test_connection.py      # Database connection test
├── README.md              # Detailed setup guide
├── wallet/                # Database wallet files
└── scripts/
    ├── setup_env.sh       # Environment setup
    └── check_setup.sh     # Verify installation
```

### Test Script Features:
- ✅ Connection validation
- ✅ Database version check
- ✅ Sample table creation/testing
- ✅ Service level verification
- ✅ Environment validation

## 🔒 Security Features

- **Network Security** - Dedicated VCN with security lists
- **SSH Access** - Key-based authentication only
- **Database Access** - Wallet-based secure connectivity
- **Firewall** - Configured for development ports
- **User Isolation** - Dedicated oracle user for database operations

## 🛠️ Troubleshooting

### Common Deployment Issues

#### 1. ADB Free Tier Quota Exceeded
**Error**: `400-QuotaExceeded, adb-free-count`

**Solutions**:
- **Recommended**: Set `is_free_tier = false` (creates paid ADB ~$2-3/month)
- **Alternative**: Delete an existing Always Free ADB in OCI Console
- **Check**: Go to Oracle Database → Autonomous Database to see current free tier usage

#### 2. Storage Auto-scaling Error
**Error**: `Auto scale for storage is not supported for Always Free`

**Solution**: Already handled automatically - auto-scaling disabled for free tier

#### 3. Access Control Error  
**Error**: `Configure access control for Autonomous Database is not supported`

**Solution**: Already handled automatically - simplified network access for compatibility

#### 4. Template Interpolation Error
**Error**: Template syntax errors in cloud-init

**Solution**: Use the provided cloud-init.yml file as-is

### Stack Management
```bash
# Via OCI Console
# - Go to Resource Manager → Stacks
# - Select your stack
# - Use Plan/Apply/Destroy actions

# Via OCI CLI
oci resource-manager stack list --compartment-id <compartment_ocid>
oci resource-manager job create-plan-job --stack-id <stack_ocid>
oci resource-manager job create-apply-job --stack-id <stack_ocid>
```

## 💰 Cost Considerations

### Always Free Tier (Default: Disabled)
- **ADB Quota**: Maximum 2 per tenancy (if exceeded, deployment fails)
- **Resources**: 1 OCPU, 20GB storage per ADB
- **Compute**: VM.Standard.E2.1.Micro (Always Free eligible)
- **Cost**: $0 (within Always Free limits)

### Paid Tier (Recommended for Templates)
- **ADB**: Starts at ~$2-3/month for minimal config (1 OCPU, 1TB storage)
- **Compute**: ~$6-10/month for small instances
- **Reliability**: No quota conflicts, consistent deployment

### 🎯 Template Recommendation:
**Set `is_free_tier = false`** by default to ensure reliable deployments for all users. Users can optionally enable free tier if their quota allows.

## 📚 Additional Resources

- [Oracle Autonomous Database Documentation](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [OCI Resource Manager Documentation](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/home.htm)
- [cx_Oracle Documentation](https://cx-oracle.readthedocs.io/)
- [Python Database API Specification](https://peps.python.org/pep-0249/)

## 🗂️ File Structure

```
oracle-adb-python-stack/
├── schema.yaml            # ORM UI configuration
├── main.tf               # Core infrastructure
├── variables.tf          # Input variables
├── outputs.tf            # Stack outputs
├── cloud-init.yml        # Instance initialization
└── README.md            # This file
```

## 🎉 Success Criteria

After successful deployment, you should be able to:

1. ✅ SSH to the compute instance
2. ✅ Switch to oracle user without issues
3. ✅ Run `python3 test_connection.py` successfully
4. ✅ See "All tests completed successfully!" message
5. ✅ Access the ADB Service Console via provided URL
6. ✅ Connect from external tools using the downloaded wallet

---

**Ready to deploy?** Upload the ZIP file to OCI Resource Manager and start building with Oracle Autonomous Database! 🚀