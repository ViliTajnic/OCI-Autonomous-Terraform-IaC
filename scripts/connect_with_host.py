#!/usr/bin/env python3
"""
Oracle ADB Connection with Host Details

This script connects to Oracle Autonomous Database and displays detailed
connection information including host details from TNS configuration.

Requirements:
- oracledb package: pip3 install --user oracledb
- Wallet files in /home/opc/wallet/
- ADMIN password and wallet password

Usage:
    python3 connect_with_host.py
"""

import oracledb
import getpass

def connect_with_host():
    """Connect to ADB and display host details from TNS configuration."""
    # Read tnsnames.ora to understand connection details
    print("📄 Reading TNS Names configuration...")
    try:
        with open('/home/opc/wallet/tnsnames.ora', 'r') as f:
            tns_content = f.read()
            print("First few lines of tnsnames.ora:")
            print('\n'.join(tns_content.split('\n')[:15]))
    except FileNotFoundError:
        print("❌ tnsnames.ora not found! Please check wallet files.")
        return
    
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
        
        # Additional connection details
        cursor.execute("""
            SELECT 
                SYS_CONTEXT('USERENV', 'SESSION_USER') as session_user,
                SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') as current_schema,
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') as client_id,
                SYS_CONTEXT('USERENV', 'IP_ADDRESS') as client_ip
            FROM dual
        """)
        
        session_info = cursor.fetchone()
        print(f"🔐 Session User: {session_info[0]}")
        print(f"📂 Current Schema: {session_info[1]}")
        print(f"🆔 Client ID: {session_info[2] or 'Not set'}")
        print(f"🌍 Client IP: {session_info[3]}")
        
        cursor.close()
        connection.close()
        
    except oracledb.DatabaseError as e:
        print(f"❌ Connection failed: {e}")
    except Exception as e:
        print(f"💥 Unexpected error: {e}")

if __name__ == "__main__":
    connect_with_host()