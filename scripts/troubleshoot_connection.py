#!/usr/bin/env python3
"""
Oracle ADB Connection Troubleshooting

This script performs comprehensive diagnostics for Oracle Autonomous Database
connectivity issues including wallet validation, driver checks, and connection testing.

Requirements:
- oracledb package: pip3 install --user oracledb
- Wallet files in /home/opc/wallet/
- ADMIN password and wallet password (optional for some checks)

Usage:
    python3 troubleshoot_connection.py
"""

import oracledb
import os
import getpass

def troubleshoot_connection():
    """Perform comprehensive connection troubleshooting."""
    print("🔧 Oracle Database Connection Troubleshooting\n")
    
    # 1. Check wallet files
    print("1️⃣ Checking wallet files...")
    wallet_dir = "/home/opc/wallet"
    required_files = ['cwallet.sso', 'tnsnames.ora', 'sqlnet.ora']
    
    wallet_ok = True
    for file in required_files:
        file_path = os.path.join(wallet_dir, file)
        if os.path.exists(file_path):
            file_size = os.path.getsize(file_path)
            print(f"✅ {file} exists ({file_size} bytes)")
        else:
            print(f"❌ {file} missing!")
            wallet_ok = False
    
    if not wallet_ok:
        print("⚠️  Wallet files are incomplete. Please download and extract wallet.zip again.")
        return
    
    # 2. Check wallet directory permissions
    print(f"\n📁 Wallet directory permissions:")
    try:
        stat_info = os.stat(wallet_dir)
        permissions = oct(stat_info.st_mode)[-3:]
        print(f"   Directory: {wallet_dir}")
        print(f"   Permissions: {permissions}")
        print(f"   Owner readable: {'✅' if os.access(wallet_dir, os.R_OK) else '❌'}")
        print(f"   Owner writable: {'✅' if os.access(wallet_dir, os.W_OK) else '❌'}")
    except Exception as e:
        print(f"❌ Cannot check permissions: {e}")
    
    # 3. Check Python oracledb installation
    print("\n2️⃣ Checking oracledb installation...")
    try:
        print(f"✅ oracledb version: {oracledb.version}")
        try:
            client_version = oracledb.clientversion()
            print(f"✅ Client version: {client_version}")
        except:
            print("ℹ️  Client version not available (normal for thin mode)")
    except Exception as e:
        print(f"❌ oracledb error: {e}")
        print("💡 Try: pip3 install --user --upgrade oracledb")
        return
    
    # 4. Check TNS configuration
    print("\n3️⃣ Checking TNS configuration...")
    try:
        tns_file = os.path.join(wallet_dir, 'tnsnames.ora')
        with open(tns_file, 'r') as f:
            content = f.read()
            
        # Extract service names
        services = []
        for line in content.split('\n'):
            if '=' in line and not line.strip().startswith('#'):
                service_name = line.split('=')[0].strip()
                if service_name and not service_name.startswith('('):
                    services.append(service_name)
        
        print(f"✅ Found {len(services)} service definitions:")
        for service in services:
            print(f"   - {service}")
            
        # Check for expected services
        expected_services = ['pythonadb_high', 'pythonadb_medium', 'pythonadb_low']
        for expected in expected_services:
            if expected in services:
                print(f"✅ Expected service '{expected}' found")
            else:
                print(f"⚠️  Expected service '{expected}' not found")
                
    except Exception as e:
        print(f"❌ Cannot read tnsnames.ora: {e}")
    
    # 5. Check sqlnet.ora configuration
    print("\n4️⃣ Checking sqlnet.ora configuration...")
    try:
        sqlnet_file = os.path.join(wallet_dir, 'sqlnet.ora')
        with open(sqlnet_file, 'r') as f:
            sqlnet_content = f.read()
        
        print("📄 sqlnet.ora contents:")
        for line in sqlnet_content.strip().split('\n'):
            if line.strip():
                print(f"   {line}")
                
        # Check for wallet location
        if 'WALLET_LOCATION' in sqlnet_content:
            print("✅ Wallet location configured")
        else:
            print("⚠️  Wallet location not found in sqlnet.ora")
            
    except Exception as e:
        print(f"❌ Cannot read sqlnet.ora: {e}")
    
    # 6. Test connection with detailed error handling
    print("\n5️⃣ Testing connection with detailed diagnostics...")
    
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
                    
                    # Get additional info
                    cursor.execute("SELECT SYS_CONTEXT('USERENV', 'SERVICE_NAME') FROM dual")
                    actual_service = cursor.fetchone()[0]
                    print(f"   Connected to service: {actual_service}")
                
                cursor.close()
                connection.close()
                
            except oracledb.DatabaseError as e:
                error_obj = e.args[0] if e.args else None
                error_code = error_obj.code if hasattr(error_obj, 'code') else 'Unknown'
                print(f"❌ {service_name}: Failed (Error {error_code})")
                print(f"   Details: {str(e)[:100]}...")
                
                # Provide specific troubleshooting tips
                if 'TNS:could not resolve' in str(e):
                    print("💡 Check service name in tnsnames.ora")
                elif 'invalid username/password' in str(e).lower():
                    print("💡 Verify ADMIN password")
                elif 'wallet' in str(e).lower():
                    print("💡 Check wallet password and files")
                elif 'network adapter' in str(e).lower():
                    print("💡 Check network connectivity and firewall")
                    
            except Exception as e:
                print(f"❌ {service_name}: Unexpected error - {e}")
    else:
        print("⏭️  Skipping connection test")
    
    # 7. System information
    print("\n6️⃣ System information...")
    try:
        import platform
        print(f"   OS: {platform.system()} {platform.release()}")
        print(f"   Python: {platform.python_version()}")
        print(f"   Architecture: {platform.machine()}")
        
        # Check network connectivity
        import subprocess
        try:
            result = subprocess.run(['ping', '-c', '1', 'oracle.com'], 
                                  capture_output=True, timeout=5)
            if result.returncode == 0:
                print("✅ Network connectivity to oracle.com: OK")
            else:
                print("❌ Network connectivity to oracle.com: Failed")
        except:
            print("⚠️  Cannot test network connectivity")
            
    except Exception as e:
        print(f"❌ Cannot get system info: {e}")
    
    print("\n🏁 Troubleshooting completed!")
    print("\nCommon solutions:")
    print("- Ensure wallet files are properly extracted")
    print("- Verify ADMIN and wallet passwords")
    print("- Check network connectivity")
    print("- Update oracledb: pip3 install --user --upgrade oracledb")

if __name__ == "__main__":
    troubleshoot_connection()