# Oracle Autonomous Database Connectivity Guide

##  [![One Click deploy to OCI](image.png)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/ViliTajnic/OCI-Autonomous-Terraform-IaC/blob/main/tf_adb_iac.zip)

## 🔗 Checking and Establishing Database Connectivity

### Step 1: System Update and Python Installation

Start with a complete system update before installing any packages:

```bash
# SSH to your instance
ssh opc@<instance_ip>

# System update - Always do this first!
sudo yum clean all
sudo yum update -y

# Check if reboot is needed (if kernel was updated)
needs-restarting -r
# If output shows reboot needed: sudo reboot

# Install EPEL repository for additional packages
sudo yum install -y epel-release

# Install development tools
sudo yum groupinstall -y "Development Tools"
sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel readline-devel sqlite-devel

# Check available Python versions
yum list available | grep python3

# Install multiple Python versions (install all available)
sudo yum install -y python3 python3-pip python3-devel
sudo yum install -y python39 python39-pip python39-devel  # If available
sudo yum install -y python3.11 python3.11-pip python3.11-devel  # If available

# Set up alternatives for Python versions
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1  # Default
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2  # If installed
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 3  # If installed

# Set up alternatives for pip versions
sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.6 1  # Default
sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.9 2  # If installed
sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 3  # If installed

# Configure which Python version to use (interactive menu)
sudo alternatives --config python3
# Choose your preferred Python version from the menu

# Configure which pip version to use (interactive menu)
sudo alternatives --config pip3
# Choose the corresponding pip version

# Verify selected versions
python3 --version
pip3 --version
which python3
which pip3

# Update pip and PATH
pip3 install --user --upgrade pip
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Oracle database driver
pip3 install --user oracledb

# Install additional useful packages
pip3 install --user pandas sqlalchemy requests

# Verify Oracle driver installation
python3 -c "import oracledb; print('oracledb version:', oracledb.version)"
```

**Managing Python Versions:**
```bash
# Check current Python alternatives
sudo alternatives --display python3

# Switch to different Python version anytime
sudo alternatives --config python3

# Switch pip version to match Python version
sudo alternatives --config pip3

# List all installed Python versions
ls -la /usr/bin/python*

# Check specific version details
/usr/bin/python3.9 --version
/usr/bin/python3.11 --version
```

**Alternative: Manual Python 3.12 Installation (if needed)**
```bash
# If latest Python version is not available in yum, compile from source
cd /tmp
wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
tar xzf Python-3.12.0.tgz
cd Python-3.12.0

# Configure and compile
./configure --enable-optimizations
make -j $(nproc)
sudo make altinstall

# Use Python 3.12
python3.12 --version
python3.12 -m pip install --user oracledb pandas sqlalchemy
```

**Check Available Python Versions:**
```bash
# Check what Python versions are available
yum list available | grep python3

# Install the highest available version
sudo yum install -y python39 python39-pip python39-devel  # Example for Python 3.9
```

### Step 2: Download and Configure Wallet

After your Terraform stack deployment completes:

1. **Download Wallet from OCI Console**
   ```bash
   # Go to: OCI Console → Oracle Database → Autonomous Database → PythonADB
   # Click "DB Connection" → Download Wallet
   # Set wallet password (remember this!) → Save as wallet.zip
   ```

2. **Transfer Wallet to Compute Instance**
   ```bash
   # From your local machine, upload wallet to the instance
   scp wallet.zip opc@<instance_ip>:~/
   
   # SSH to your instance
   ssh opc@<instance_ip>
   
   # Create wallet directory and extract
   mkdir -p ~/wallet
   unzip wallet.zip -d ~/wallet/
   
   # Verify wallet contents
   ls -la ~/wallet/
   # Should show: cwallet.sso, tnsnames.ora, sqlnet.ora, etc.
   ```

### Step 3: Verify Network Connectivity

```bash
# Check if instance can reach Oracle services
ping oracle.com

# Verify Python oracledb installation
python3 -c "import oracledb; print('✅ oracledb version:', oracledb.version)"

# Check wallet files
cat ~/wallet/tnsnames.ora | head -10
```

### Step 4: Test Basic Database Connection

Create a simple connectivity test script using the modern oracledb driver:

```python
# Create file: test_basic_connection.py
import oracledb
import getpass

def test_connection():
    try:
        # Database connection parameters
        username = "ADMIN"
        password = getpass.getpass("Enter ADMIN password: ")
        wallet_password = getpass.getpass("Enter wallet password: ")
        
        # Try different service names (high, medium, low performance)
        service_names = ["pythonadb_high", "pythonadb_medium", "pythonadb_low"]
        
        for service_name in service_names:
            try:
                print(f"\n🔍 Testing connection to: {service_name}")
                
                # Create connection using wallet with password
                connection = oracledb.connect(
                    user=username,
                    password=password,
                    dsn=service_name,
                    config_dir="/home/opc/wallet",
                    wallet_location="/home/opc/wallet",
                    wallet_password=wallet_password
                )
                
                print(f"✅ Successfully connected to {service_name}")
                
                # Test basic query
                cursor = connection.cursor()
                cursor.execute("SELECT 'Hello from Oracle ADB on ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual")
                result = cursor.fetchone()
                print(f"📋 Query result: {result[0]}")
                
                # Get database info
                cursor.execute("SELECT banner FROM v$version WHERE banner LIKE 'Oracle%'")
                db_version = cursor.fetchone()
                print(f"🗄️  Database: {db_version[0]}")
                
                # Show current user and database
                cursor.execute("SELECT USER, SYS_CONTEXT('USERENV', 'DB_NAME') FROM dual")
                user_info = cursor.fetchone()
                print(f"👤 Connected as: {user_info[0]} to database: {user_info[1]}")
                
                cursor.close()
                connection.close()
                print(f"🔌 Connection to {service_name} closed successfully\n")
                break
                
            except oracledb.DatabaseError as e:
                print(f"❌ Failed to connect to {service_name}: {e}")
                continue
                
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    test_connection()
```

Run the test:
```bash
python3 test_basic_connection.py
```

### Step 5: Advanced Connection and Query Examples

#### Method 1: Connection with Host Details from TNS

```python
# Create file: connect_with_host.py
import oracledb
import getpass

def connect_with_host():
    # Read tnsnames.ora to understand connection details
    print("📄 Reading TNS Names configuration...")
    with open('/home/opc/wallet/tnsnames.ora', 'r') as f:
        tns_content = f.read()
        print("First few lines of tnsnames.ora:")
        print('\n'.join(tns_content.split('\n')[:15]))
    
    # Connection parameters
    username = "ADMIN"
    password = getpass.getpass("Enter ADMIN password: ")
    wallet_password = getpass.getpass("Enter wallet password: ")
    
    try:
        # Connect using service name with wallet
        connection = oracledb.connect(
            user=username,
            password=password,
            dsn="pythonadb_high",
            config_dir="/home/opc/wallet",
            wallet_location="/home/opc/wallet",
            wallet_password=wallet_password
        )
        
        print("✅ Connected successfully!")
        
        # Get detailed connection info
        cursor = connection.cursor()
        
        # Database and instance information
        cursor.execute("""
            SELECT 
                SYS_CONTEXT('USERENV', 'DB_NAME') as db_name,
                SYS_CONTEXT('USERENV', 'INSTANCE_NAME') as instance_name,
                SYS_CONTEXT('USERENV', 'SERVER_HOST') as server_host,
                SYS_CONTEXT('USERENV', 'SERVICE_NAME') as service_name
            FROM dual
        """)
        
        db_info = cursor.fetchone()
        print(f"🏷️  Database Name: {db_info[0]}")
        print(f"🖥️  Instance Name: {db_info[1]}")
        print(f"🌐 Server Host: {db_info[2]}")
        print(f"⚙️  Service Name: {db_info[3]}")
        
        cursor.close()
        connection.close()
        
    except oracledb.DatabaseError as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    connect_with_host()
```

#### Method 2: Sample Queries and Operations

```python
# Create file: sample_queries.py
import oracledb
import getpass

def run_sample_queries():
    username = "ADMIN"
    password = getpass.getpass("Enter ADMIN password: ")
    wallet_password = getpass.getpass("Enter wallet password: ")
    
    try:
        # Connect to database
        connection = oracledb.connect(
            user=username,
            password=password,
            dsn="pythonadb_high",
            config_dir="/home/opc/wallet",
            wallet_location="/home/opc/wallet",
            wallet_password=wallet_password
        )
        
        cursor = connection.cursor()
        print("🚀 Running sample queries...\n")
        
        # 1. Create a sample table
        print("1️⃣ Creating sample table...")
        try:
            cursor.execute("DROP TABLE sample_employees")
        except:
            pass  # Table might not exist
            
        cursor.execute("""
            CREATE TABLE sample_employees (
                id NUMBER GENERATED BY DEFAULT AS IDENTITY,
                name VARCHAR2(100),
                department VARCHAR2(50),
                salary NUMBER(10,2),
                hire_date DATE
            )
        """)
        print("✅ Table created successfully")
        
        # 2. Insert sample data
        print("\n2️⃣ Inserting sample data...")
        sample_data = [
            ('John Doe', 'Engineering', 75000.00, '2023-01-15'),
            ('Jane Smith', 'Marketing', 65000.00, '2023-02-20'),
            ('Bob Johnson', 'Sales', 55000.00, '2023-03-10'),
            ('Alice Brown', 'Engineering', 80000.00, '2023-01-25')
        ]
        
        for emp in sample_data:
            cursor.execute("""
                INSERT INTO sample_employees (name, department, salary, hire_date) 
                VALUES (:1, :2, :3, TO_DATE(:4, 'YYYY-MM-DD'))
            """, emp)
        
        connection.commit()
        print(f"✅ Inserted {len(sample_data)} records")
        
        # 3. Query data
        print("\n3️⃣ Querying data...")
        cursor.execute("""
            SELECT id, name, department, salary, 
                   TO_CHAR(hire_date, 'YYYY-MM-DD') as hire_date
            FROM sample_employees 
            ORDER BY salary DESC
        """)
        
        print("📊 Employee Data:")
        print(f"{'ID':<3} {'Name':<15} {'Department':<12} {'Salary':<10} {'Hire Date':<12}")
        print("-" * 55)
        
        for row in cursor.fetchall():
            print(f"{row[0]:<3} {row[1]:<15} {row[2]:<12} ${row[3]:<9,.2f} {row[4]:<12}")
        
        # 4. Aggregate queries
        print("\n4️⃣ Running aggregate queries...")
        
        # Average salary by department
        cursor.execute("""
            SELECT department, 
                   COUNT(*) as emp_count,
                   AVG(salary) as avg_salary,
                   MAX(salary) as max_salary
            FROM sample_employees 
            GROUP BY department
            ORDER BY avg_salary DESC
        """)
        
        print("\n📈 Department Statistics:")
        print(f"{'Department':<12} {'Count':<6} {'Avg Salary':<12} {'Max Salary':<12}")
        print("-" * 45)
        
        for row in cursor.fetchall():
            print(f"{row[0]:<12} {row[1]:<6} ${row[2]:<11,.2f} ${row[3]:<11,.2f}")
        
        # 5. Database metadata
        print("\n5️⃣ Database metadata...")
        cursor.execute("""
            SELECT table_name, num_rows, last_analyzed 
            FROM user_tables 
            WHERE table_name = 'SAMPLE_EMPLOYEES'
        """)
        
        metadata = cursor.fetchone()
        if metadata:
            print(f"📋 Table: {metadata[0]}")
            print(f"📊 Rows: {metadata[1] or 'Not analyzed'}")
            print(f"📅 Last analyzed: {metadata[2] or 'Never'}")
        
        # 6. Clean up (optional)
        print("\n6️⃣ Cleaning up...")
        cursor.execute("DROP TABLE sample_employees")
        print("✅ Sample table dropped")
        
        cursor.close()
        connection.close()
        print("\n🎉 All operations completed successfully!")
        
    except oracledb.DatabaseError as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    run_sample_queries()
```

### Step 6: Connection Troubleshooting

```python
# Create file: troubleshoot_connection.py
import oracledb
import os
import getpass

def troubleshoot_connection():
    print("🔧 Oracle Database Connection Troubleshooting\n")
    
    # 1. Check wallet files
    print("1️⃣ Checking wallet files...")
    wallet_dir = "/home/opc/wallet"
    required_files = ['cwallet.sso', 'tnsnames.ora', 'sqlnet.ora']
    
    for file in required_files:
        file_path = os.path.join(wallet_dir, file)
        if os.path.exists(file_path):
            print(f"✅ {file} exists")
        else:
            print(f"❌ {file} missing!")
    
    # 2. Check Python oracledb
    print("\n2️⃣ Checking oracledb installation...")
    try:
        print(f"✅ oracledb version: {oracledb.version}")
        print(f"✅ Client version: {oracledb.clientversion()}")
    except Exception as e:
        print(f"❌ oracledb error: {e}")
    
    # 3. Test connection with detailed error handling
    print("\n3️⃣ Testing connection with detailed diagnostics...")
    
    username = "ADMIN"
    password = getpass.getpass("Enter ADMIN password (or press Enter to skip): ")
    
    if password:
        wallet_password = getpass.getpass("Enter wallet password: ")
        service_names = ["pythonadb_high", "pythonadb_medium", "pythonadb_low"]
        
        for service_name in service_names:
            try:
                print(f"\n🔍 Testing {service_name}...")
                connection = oracledb.connect(
                    user=username,
                    password=password,
                    dsn=service_name,
                    config_dir=wallet_dir,
                    wallet_location=wallet_dir,
                    wallet_password=wallet_password
                )
                
                cursor = connection.cursor()
                cursor.execute("SELECT 1 FROM dual")
                result = cursor.fetchone()
                
                if result and result[0] == 1:
                    print(f"✅ {service_name}: Connection successful!")
                
                cursor.close()
                connection.close()
                
            except oracledb.DatabaseError as e:
                error_code = e.args[0].code if hasattr(e.args[0], 'code') else 'Unknown'
                print(f"❌ {service_name}: Failed (Error {error_code})")
                print(f"   Details: {str(e)[:100]}...")
    
    # 4. Check TNS configuration
    print("\n4️⃣ Checking TNS configuration...")
    try:
        with open(os.path.join(wallet_dir, 'tnsnames.ora'), 'r') as f:
            content = f.read()
            services = [line.split('=')[0].strip() for line in content.split('\n') 
                       if '=' in line and not line.strip().startswith('#')]
            print(f"✅ Found {len(services)} service definitions:")
            for service in services[:5]:  # Show first 5
                print(f"   - {service}")
    except Exception as e:
        print(f"❌ Cannot read tnsnames.ora: {e}")

if __name__ == "__main__":
    troubleshoot_connection()
```

Run these scripts:
```bash
# Test basic connectivity
python3 test_basic_connection.py

# Get detailed connection info
python3 connect_with_host.py

# Run sample queries and operations
python3 sample_queries.py

# Troubleshoot connection issues
python3 troubleshoot_connection.py
```

### Step 7: Quick Connection Test

For a fast connectivity check, create this simple script:

```python
# Create file: quick_test.py
import oracledb
import getpass

try:
    # Quick connection test
    admin_password = getpass.getpass("Enter ADMIN password: ")
    wallet_password = getpass.getpass("Enter wallet password: ")
    
    conn = oracledb.connect(
        user="ADMIN",
        password=admin_password,
        dsn="pythonadb_high",
        config_dir="/home/opc/wallet",
        wallet_location="/home/opc/wallet",
        wallet_password=wallet_password
    )
    
    cursor = conn.cursor()
    cursor.execute("SELECT 'Connection successful at ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual")
    print("✅", cursor.fetchone()[0])
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print("❌ Connection failed:", e)
```

```bash
python3 quick_test.py
```

## 🎯 Expected Results

When everything is working correctly, you should see:
- ✅ Successful connection to ADB
- ✅ Query results returned
- ✅ Database version information
- ✅ No authentication or network errors

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| `TNS:could not resolve the connect identifier` | Check wallet files and service names |
| `Invalid username/password` | Verify ADMIN password |
| `Network adapter could not establish connection` | Check network connectivity and firewall |
| `Wallet not found` | Verify wallet path and permissions |
| `Module not found: oracledb` | Run `pip3 install oracledb` |