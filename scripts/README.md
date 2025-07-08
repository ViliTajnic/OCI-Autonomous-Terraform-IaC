# Python Scripts for Oracle ADB Connectivity

This folder contains Python scripts for testing and working with the Oracle Autonomous Database deployed by the Terraform stack in this repository.

## 📋 Prerequisites

### System Requirements
- Oracle Linux instance (deployed by Terraform stack)
- Python 3.9+ installed
- Network connectivity to Oracle Cloud services
- SSH access to the compute instance

### Required Files
- Oracle ADB wallet files downloaded and extracted to `/home/opc/wallet/`
- ADMIN password for the database
- Wallet password (set when downloading wallet)

## 🚀 Quick Start

1. **Install Dependencies**
   ```bash
   # Navigate to scripts folder
   cd scripts/
   
   # Install required Python packages
   pip3 install --user -r requirements.txt
   ```

2. **Quick Connectivity Test**
   ```bash
   python3 quick_test.py
   ```

3. **Run Comprehensive Tests**
   ```bash
   python3 test_basic_connection.py
   ```

## 📁 Available Scripts

### Core Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **`quick_test.py`** | Fast connectivity verification | First test after setup, automation, CI/CD |
| **`test_basic_connection.py`** | Comprehensive connectivity test | Initial setup validation, testing all services |
| **`connect_with_host.py`** | Connection with detailed host info | Understanding connection details, debugging |
| **`sample_queries.py`** | Database operations examples | Learning database operations, testing functionality |
| **`troubleshoot_connection.py`** | Comprehensive diagnostic tool | Debugging connection issues, system validation |

### Script Details

#### `quick_test.py`
- **Purpose**: Minimal, fast connectivity check
- **Output**: Simple success/failure message
- **Exit Code**: 0 for success, 1 for failure
- **Best For**: Automation scripts, quick verification

#### `test_basic_connection.py`
- **Purpose**: Test all service names with detailed output
- **Features**: Tests high/medium/low services, database info, user validation
- **Best For**: Initial setup verification, comprehensive testing

#### `connect_with_host.py`
- **Purpose**: Display detailed connection and host information
- **Features**: TNS configuration, server details, session information
- **Best For**: Understanding connection setup, troubleshooting

#### `sample_queries.py`
- **Purpose**: Demonstrate complete database operations
- **Features**: Table creation, data insertion, complex queries, metadata
- **Best For**: Learning database operations, testing full functionality

#### `troubleshoot_connection.py`
- **Purpose**: Comprehensive diagnostic and troubleshooting
- **Features**: Wallet validation, permission checks, detailed error analysis
- **Best For**: Debugging connection issues, system validation

## 💻 Usage Examples

### Basic Usage
```bash
# Quick connectivity check
python3 quick_test.py

# Test all connection services
python3 test_basic_connection.py

# Get detailed connection information
python3 connect_with_host.py

# Run sample database operations
python3 sample_queries.py

# Troubleshoot issues
python3 troubleshoot_connection.py
```

### Automation Usage
```bash
# Check connectivity with exit code
python3 quick_test.py
if [ $? -eq 0 ]; then
    echo "Database connection successful"
else
    echo "Database connection failed"
    exit 1
fi
```

## 🔧 Troubleshooting

### Common Issues

| Error | Possible Cause | Solution |
|-------|---------------|----------|
| `ModuleNotFoundError: No module named 'oracledb'` | Missing driver | `pip3 install --user oracledb` |
| `TNS:could not resolve the connect identifier` | Wallet issues | Check wallet files and service names |
| `Invalid username/password` | Wrong credentials | Verify ADMIN password |
| `Network adapter could not establish connection` | Network issues | Check connectivity and firewall |
| `Wallet not found` | Missing wallet | Download and extract wallet files |

### Diagnostic Steps

1. **Run troubleshoot script**:
   ```bash
   python3 troubleshoot_connection.py
   ```

2. **Check wallet files**:
   ```bash
   ls -la ~/wallet/
   # Should show: cwallet.sso, tnsnames.ora, sqlnet.ora
   ```

3. **Verify Python installation**:
   ```bash
   python3 -c "import oracledb; print('oracledb version:', oracledb.version)"
   ```

4. **Test network connectivity**:
   ```bash
   ping oracle.com
   ```

## 🔒 Security Notes

- **Passwords**: All scripts use `getpass` for secure password input
- **Wallet Files**: Ensure proper permissions: `chmod 600 ~/wallet/*`
- **Credentials**: Never hardcode passwords in scripts
- **Network**: Ensure proper firewall rules for Oracle database ports

## 📚 Additional Resources

- [Oracle python-oracledb Documentation](https://python-oracledb.readthedocs.io/)
- [Oracle Autonomous Database Documentation](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [OCI Terraform Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)

## 🤝 Contributing

When contributing new scripts:

1. Follow the existing code style and structure
2. Include comprehensive docstrings
3. Add proper error handling
4. Use `getpass` for password input
5. Update this README with script descriptions
6. Test thoroughly before submitting

## 📄 License

These scripts are provided as examples for the OCI Autonomous Terraform IaC repository. Use and modify as needed for your specific requirements.