#!/bin/bash

# Database initialization script for nutriLogger
# Creates database 'myNutriLoggerInfo' in the chosen database system

DB_NAME="myNutriLoggerInfo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Nutrition Logger Database Initialization"
echo "=========================================="
echo ""
echo "Select a database system:"
echo "1) SQLite"
echo "2) MariaDB"
echo "3) PostgreSQL"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "Creating SQLite database: $DB_NAME.db"
        if sqlite3 "$DB_NAME.db" "SELECT 1;" > /dev/null 2>&1; then
            echo "✓ SQLite database '$DB_NAME.db' created successfully!"
            echo "  Location: $(pwd)/$DB_NAME.db"
        else
            echo "✗ Failed to create SQLite database. Make sure sqlite3 is installed."
            exit 1
        fi
        
        echo ""
        echo "Creating SQLite tables..."
        # Source dbUtils.sh to get the table creation functions
        source "$SCRIPT_DIR/dbUtils.sh"
        if sqlite_create_tables; then
            echo "✓ SQLite tables created successfully!"
        else
            echo "✗ Failed to create SQLite tables."
            exit 1
        fi
        
        echo ""
        echo "Setting up analytical functions and views..."
        if python3 "$SCRIPT_DIR/sqlite_db.py"; then
            echo "✓ SQLite analytical functions and views created successfully!"
        else
            echo "✗ Failed to setup analytical functions and views."
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "Creating MariaDB database: $DB_NAME"
        read -p "Enter MariaDB username (default: root): " mariadb_user
        mariadb_user=${mariadb_user:-root}
        read -sp "Enter MariaDB password: " mariadb_pass
        echo ""
        
        if [ -z "$mariadb_pass" ]; then
            mariadb -u "$mariadb_user" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null
        else
            mariadb -u "$mariadb_user" -p"$mariadb_pass" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null
        fi
        
        if [ $? -eq 0 ]; then
            echo "✓ MariaDB database '$DB_NAME' created successfully!"
        else
            echo "✗ Failed to create MariaDB database. Check your credentials and MariaDB connection."
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "Creating PostgreSQL database: $DB_NAME"
        read -p "Enter PostgreSQL username (default: postgres): " pg_user
        pg_user=${pg_user:-postgres}
        
        createdb -U "$pg_user" "$DB_NAME" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✓ PostgreSQL database '$DB_NAME' created successfully!"
        else
            echo "✗ Failed to create PostgreSQL database. Check your PostgreSQL setup and user."
            exit 1
        fi
        ;;
    *)
        echo "✗ Invalid choice. Please enter a number between 1 and 3."
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Database initialization and setup complete!"
echo "=========================================="
