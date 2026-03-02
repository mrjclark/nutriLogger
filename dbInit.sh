#!/bin/bash

# Database initialization script for nutriLogger
# Creates database 'myNutriLoggerInfo' in the chosen database system

# Source database utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dbUtils.sh"

DB_NAME="myNutriLoggerInfo"

# Detect operating system using utility function
echo "Detecting operating system..."
OS=$(detect_os)
echo "✓ Detected OS: $OS"
echo ""

echo "=========================================="
echo "Nutrition Logger Database Initialization"
echo "=========================================="
echo ""
echo "Select a database system:"
echo "1) SQLite"
echo "2) MySQL"
echo "3) MariaDB"
echo "4) PostgreSQL"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        # Install SQLite for the detected OS
        case $OS in
            ubuntu|debian)
                echo "Updating package manager..."
                sudo apt-get update -qq
                echo "Installing SQLite..."
                sudo apt-get install -y sqlite3 > /dev/null 2>&1
                ;;
            centos|rhel|fedora)
                echo "Installing SQLite..."
                sudo yum install -y sqlite > /dev/null 2>&1
                ;;
            alpine)
                echo "Installing SQLite..."
                sudo apk add --no-cache sqlite > /dev/null 2>&1
                ;;
            macos)
                echo "Note: macOS detected. Using Homebrew for package installation."
                echo "Make sure Homebrew is installed. If not, visit https://brew.sh"
                echo "Installing SQLite..."
                brew install sqlite > /dev/null 2>&1
                ;;
            *)
                echo "⚠ Unknown OS: $OS"
                echo "Please manually ensure SQLite is installed."
                ;;
        esac
        
        echo ""
        echo "Creating SQLite database: $DB_NAME.db"
        sqlite_create_database && sqlite_create_tables
        
        if [ $? -eq 0 ]; then
            echo "✓ SQLite database '$DB_NAME.db' created successfully!"
            echo "  Location: $(pwd)/$DB_NAME.db"
            # Offer to encrypt the SQLite database file
            read -p "Would you like to encrypt the database file now? (y/N): " enc_choice
            enc_choice=${enc_choice:-N}
            if [[ "$enc_choice" =~ ^[Yy]$ ]]; then
                if ! command -v openssl >/dev/null 2>&1; then
                    echo "openssl not found. Attempting to install openssl..."
                    case $OS in
                        ubuntu|debian)
                            sudo apt-get update -qq && sudo apt-get install -y openssl > /dev/null 2>&1
                            ;;
                        centos|rhel|fedora)
                            sudo yum install -y openssl > /dev/null 2>&1
                            ;;
                        alpine)
                            sudo apk add --no-cache openssl > /dev/null 2>&1
                            ;;
                        macos)
                            brew install openssl > /dev/null 2>&1
                            ;;
                        *)
                            echo "Please install openssl manually and re-run this script."
                            ;;
                    esac
                fi

                # Prompt for passphrase and call helper
                echo "Encrypting database. You will be prompted for a passphrase."
                sqlite_encrypt_db "${DB_NAME}.db"
                if [ $? -eq 0 ]; then
                    echo "✓ Database encrypted successfully."
                else
                    echo "✗ Database encryption failed or was cancelled."
                fi
            fi
        else
            echo "✗ Failed to create SQLite database. Make sure sqlite3 is installed."
            exit 1
        fi
        ;;
    2)
        # Install MySQL for the detected OS
        case $OS in
            ubuntu|debian)
                echo "Updating package manager..."
                sudo apt-get update -qq
                echo "Installing MySQL..."
                sudo apt-get install -y mysql-server > /dev/null 2>&1
                ;;
            centos|rhel|fedora)
                echo "Installing MySQL..."
                sudo yum install -y mysql-server > /dev/null 2>&1
                ;;
            alpine)
                echo "Installing MySQL..."
                sudo apk add --no-cache mysql > /dev/null 2>&1
                ;;
            macos)
                echo "Note: macOS detected. Using Homebrew for package installation."
                echo "Make sure Homebrew is installed. If not, visit https://brew.sh"
                echo "Installing MySQL..."
                brew install mysql > /dev/null 2>&1
                ;;
            *)
                echo "⚠ Unknown OS: $OS"
                echo "Please manually ensure MySQL is installed."
                ;;
        esac
        
        echo ""
        echo "Creating MySQL database: $DB_NAME"
        read -p "Enter MySQL username (default: root): " mysql_user
        mysql_user=${mysql_user:-root}
        read -sp "Enter MySQL password: " mysql_pass
        echo ""
        
        mysql_create_database "$mysql_user" "$mysql_pass" && mysql_create_tables "$mysql_user" "$mysql_pass"
        
        if [ $? -eq 0 ]; then
            echo "✓ MySQL database '$DB_NAME' created successfully!"
        else
            echo "✗ Failed to create MySQL database. Check your credentials and MySQL connection."
            exit 1
        fi
        ;;
    3)
        # Install MariaDB for the detected OS
        case $OS in
            ubuntu|debian)
                echo "Updating package manager..."
                sudo apt-get update -qq
                echo "Installing MariaDB..."
                sudo apt-get install -y mariadb-server > /dev/null 2>&1
                ;;
            centos|rhel|fedora)
                echo "Installing MariaDB..."
                sudo yum install -y mariadb-server > /dev/null 2>&1
                ;;
            alpine)
                echo "Installing MariaDB..."
                sudo apk add --no-cache mariadb > /dev/null 2>&1
                ;;
            macos)
                echo "Note: macOS detected. Using Homebrew for package installation."
                echo "Make sure Homebrew is installed. If not, visit https://brew.sh"
                echo "Installing MariaDB..."
                brew install mariadb > /dev/null 2>&1
                ;;
            *)
                echo "⚠ Unknown OS: $OS"
                echo "Please manually ensure MariaDB is installed."
                ;;
        esac
        
        echo ""
        echo "Creating MariaDB database: $DB_NAME"
        read -p "Enter MariaDB username (default: root): " mariadb_user
        mariadb_user=${mariadb_user:-root}
        read -sp "Enter MariaDB password: " mariadb_pass
        echo ""
        
        mysql_create_database "$mariadb_user" "$mariadb_pass" && mysql_create_tables "$mariadb_user" "$mariadb_pass"
        
        if [ $? -eq 0 ]; then
            echo "✓ MariaDB database '$DB_NAME' created successfully!"
        else
            echo "✗ Failed to create MariaDB database. Check your credentials and MariaDB connection."
            exit 1
        fi
        ;;
    4)
        # Install PostgreSQL for the detected OS
        case $OS in
            ubuntu|debian)
                echo "Updating package manager..."
                sudo apt-get update -qq
                echo "Installing PostgreSQL..."
                sudo apt-get install -y postgresql postgresql-contrib > /dev/null 2>&1
                ;;
            centos|rhel|fedora)
                echo "Installing PostgreSQL..."
                sudo yum install -y postgresql-server postgresql-contrib > /dev/null 2>&1
                ;;
            alpine)
                echo "Installing PostgreSQL..."
                sudo apk add --no-cache postgresql postgresql-contrib > /dev/null 2>&1
                ;;
            macos)
                echo "Note: macOS detected. Using Homebrew for package installation."
                echo "Make sure Homebrew is installed. If not, visit https://brew.sh"
                echo "Installing PostgreSQL..."
                brew install postgresql > /dev/null 2>&1
                ;;
            *)
                echo "⚠ Unknown OS: $OS"
                echo "Please manually ensure PostgreSQL is installed."
                ;;
        esac
        
        echo ""
        echo "Creating PostgreSQL database: $DB_NAME"
        read -p "Enter PostgreSQL username (default: postgres): " pg_user
        pg_user=${pg_user:-postgres}
        
        postgresql_create_database "$pg_user" && postgresql_create_tables "$pg_user"
        
        if [ $? -eq 0 ]; then
            echo "✓ PostgreSQL database '$DB_NAME' created successfully!"
        else
            echo "✗ Failed to create PostgreSQL database. Check your PostgreSQL setup and user."
            exit 1
        fi
        ;;
    *)
        echo "✗ Invalid choice. Please enter a number between 1 and 4."
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Database initialization complete!"
echo "=========================================="
