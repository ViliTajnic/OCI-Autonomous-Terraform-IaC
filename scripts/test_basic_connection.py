#!/usr/bin/env python3
"""
Basic Oracle Autonomous Database Connection Test

This script tests connectivity to Oracle Autonomous Database using different service names
and validates the connection with basic queries.

Requirements:
- oracledb package: pip3 install --user oracledb
- Wallet files in /home/opc/wallet/
- ADMIN password and wallet password

Usage:
    python3 test_basic_connection.py
"""

import oracledb
import getpass

def test_connection():
    """Test database connection with different service names."""
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