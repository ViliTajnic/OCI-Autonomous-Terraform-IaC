#!/usr/bin/env python3
"""
Quick Oracle ADB Connection Test

Simple script for fast connectivity testing to Oracle Autonomous Database.
Minimal output, ideal for automation or quick verification.

Requirements:
- oracledb package: pip3 install --user oracledb
- Wallet files in /home/opc/wallet/
- ADMIN password and wallet password

Usage:
    python3 quick_test.py
"""

import oracledb
import getpass
import sys

def quick_test():
    """Perform a quick connection test."""
    try:
        # Get credentials
        admin_password = getpass.getpass("Enter ADMIN password: ")
        wallet_password = getpass.getpass("Enter wallet password: ")
        
        # Quick connection test
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
        result = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        print("✅", result)
        return True
        
    except oracledb.DatabaseError as e:
        error_obj = e.args[0] if e.args else None
        error_code = error_obj.code if hasattr(error_obj, 'code') else 'Unknown'
        print(f"❌ Connection failed (Error {error_code}): {e}")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = quick_test()
    sys.exit(0 if success else 1)