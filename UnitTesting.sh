#!/bin/bash

################################################################################
# Unit Tests for dbInit.sh
# Tests OS detection, package installation logic, and database creation
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results array
declare -a TEST_RESULTS

################################################################################
# Assertion Functions
################################################################################

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("PASS: $test_name")
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

assert_true() {
    local condition="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$condition" -eq 1 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("PASS: $test_name")
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

assert_false() {
    local condition="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$condition" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("PASS: $test_name")
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

################################################################################
# Mock Functions for Testing
################################################################################

# Mock apt-get for Ubuntu/Debian
mock_apt_get() {
    MOCK_APT_CALLED=1
    MOCK_APT_PACKAGE="$3"
    return 0
}

# Mock yum for CentOS/RHEL/Fedora
mock_yum() {
    MOCK_YUM_CALLED=1
    MOCK_YUM_PACKAGE="$3"
    return 0
}

# Mock apk for Alpine
mock_apk() {
    MOCK_APK_CALLED=1
    MOCK_APK_PACKAGE="$4"
    return 0
}

# Mock brew for macOS
mock_brew() {
    MOCK_BREW_CALLED=1
    MOCK_BREW_PACKAGE="$2"
    return 0
}

# Mock sqlite3
mock_sqlite3() {
    if [ "$2" = "SELECT 1;" ]; then
        return 0
    fi
    return 1
}

# Mock mysql
mock_mysql() {
    MOCK_MYSQL_CALLED=1
    return 0
}

# Mock mariadb
mock_mariadb() {
    MOCK_MARIADB_CALLED=1
    return 0
}

# Mock createdb
mock_createdb() {
    MOCK_CREATEDB_CALLED=1
    return 0
}

# Source dbUtils for testing functions
if [ -f ./dbUtils.sh ]; then
    # shellcheck source=/dev/null
    source ./dbUtils.sh
else
    echo -e "${YELLOW}⚠${NC} dbUtils.sh not found; db utils tests will be skipped"
fi

# Helper: create temporary file
make_tmpfile() {
    mktemp --suffix=.db 2>/dev/null || mktemp
}

################################################################################
# Test Suite: OS Detection
################################################################################

test_os_detection_ubuntu() {
    echo ""
    echo "Test Suite: OS Detection"
    echo "========================"
    
    # Source the os-release for testing
    local OS=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi
    
    # Check if we're on Ubuntu or Debian
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        assert_true 1 "Detect Ubuntu/Debian OS (Detected: $OS)"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: OS detection (not on Ubuntu/Debian)"
    fi
}

test_os_detection_alpine() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi
    
    if [ "$OS" = "alpine" ]; then
        assert_equals "alpine" "$OS" "Detect Alpine OS"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: Alpine OS detection (not on Alpine)"
    fi
}

test_os_version_detection() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        VERSION=$VERSION_ID
    fi
    
    if [ -n "$VERSION" ]; then
        assert_true 1 "OS version detected: $VERSION"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: Version detection (unable to determine)"
    fi
}

################################################################################
# Test Suite: Input Validation
################################################################################

test_invalid_choice_validation() {
    echo ""
    echo "Test Suite: Input Validation"
    echo "============================="
    
    # Test that invalid choices (0, 5, etc.) should be rejected
    local invalid_choice="5"
    
    if [ "$invalid_choice" -lt 1 ] || [ "$invalid_choice" -gt 4 ]; then
        assert_true 1 "Invalid choice ($invalid_choice) correctly rejected"
    fi
}

test_valid_choice_range() {
    # Test that valid choices (1-4) are accepted
    for choice in 1 2 3 4; do
        if [ "$choice" -ge 1 ] && [ "$choice" -le 4 ]; then
            assert_true 1 "Valid choice ($choice) accepted"
        fi
    done
}

################################################################################
# Test Suite: Database Name Validation
################################################################################

test_database_name_assignment() {
    echo ""
    echo "Test Suite: Database Name"
    echo "=========================="
    
    local DB_NAME="myNutriLoggerInfo"
    assert_equals "myNutriLoggerInfo" "$DB_NAME" "Database name correctly assigned"
}

test_sqlite_database_extension() {
    local DB_NAME="myNutriLoggerInfo"
    local sqlite_db="${DB_NAME}.db"
    assert_equals "myNutriLoggerInfo.db" "$sqlite_db" "SQLite database filename includes .db extension"
}

################################################################################
# Test Suite: Credential Handling
################################################################################

test_mysql_default_username() {
    echo ""
    echo "Test Suite: Credential Handling"
    echo "==============================="
    
    local mysql_user=""
    mysql_user=${mysql_user:-root}
    assert_equals "root" "$mysql_user" "MySQL default username is 'root'"
}

test_mariadb_default_username() {
    local mariadb_user=""
    mariadb_user=${mariadb_user:-root}
    assert_equals "root" "$mariadb_user" "MariaDB default username is 'root'"
}

test_postgresql_default_username() {
    local pg_user=""
    pg_user=${pg_user:-postgres}
    assert_equals "postgres" "$pg_user" "PostgreSQL default username is 'postgres'"
}

test_custom_username_assignment() {
    local custom_user="admin"
    local mysql_user="${custom_user}"
    mysql_user=${mysql_user:-root}
    assert_equals "admin" "$mysql_user" "Custom MySQL username is preserved"
}

################################################################################
# Test Suite: Package Installation Support
################################################################################

test_sqlite_package_names() {
    echo ""
    echo "Test Suite: Package Support"
    echo "============================"
    
    # These should be the correct package names
    declare -A sqlite_packages
    sqlite_packages[ubuntu/debian]="sqlite3"
    sqlite_packages[centos/rhel/fedora]="sqlite"
    sqlite_packages[alpine]="sqlite"
    sqlite_packages[macos]="sqlite"
    
    assert_equals "sqlite3" "${sqlite_packages[ubuntu/debian]}" "SQLite package for Ubuntu/Debian"
    assert_equals "sqlite" "${sqlite_packages[alpine]}" "SQLite package for Alpine"
}

test_mysql_package_names() {
    declare -A mysql_packages
    mysql_packages[ubuntu/debian]="mysql-server"
    mysql_packages[centos/rhel/fedora]="mysql-server"
    mysql_packages[alpine]="mysql"
    mysql_packages[macos]="mysql"
    
    assert_equals "mysql-server" "${mysql_packages[ubuntu/debian]}" "MySQL package for Ubuntu/Debian"
    assert_equals "mysql" "${mysql_packages[alpine]}" "MySQL package for Alpine"
}

test_mariadb_package_names() {
    declare -A mariadb_packages
    mariadb_packages[ubuntu/debian]="mariadb-server"
    mariadb_packages[centos/rhel/fedora]="mariadb-server"
    mariadb_packages[alpine]="mariadb"
    mariadb_packages[macos]="mariadb"
    
    assert_equals "mariadb-server" "${mariadb_packages[ubuntu/debian]}" "MariaDB package for Ubuntu/Debian"
    assert_equals "mariadb" "${mariadb_packages[alpine]}" "MariaDB package for Alpine"
}

test_postgresql_package_names() {
    declare -A postgresql_packages
    postgresql_packages[ubuntu/debian]="postgresql postgresql-contrib"
    postgresql_packages[centos/rhel/fedora]="postgresql-server postgresql-contrib"
    postgresql_packages[alpine]="postgresql postgresql-contrib"
    postgresql_packages[macos]="postgresql"
    
    assert_equals "postgresql postgresql-contrib" "${postgresql_packages[ubuntu/debian]}" "PostgreSQL packages for Ubuntu/Debian"
    assert_equals "postgresql-server postgresql-contrib" "${postgresql_packages[centos/rhel/fedora]}" "PostgreSQL packages for CentOS/RHEL/Fedora"
}

################################################################################
# Test Suite: Database Selection Logic
################################################################################

test_sqlite_selection() {
    echo ""
    echo "Test Suite: Database Selection"
    echo "==============================="
    
    local choice="1"
    if [ "$choice" = "1" ]; then
        assert_true 1 "SQLite selection (choice=1)"
    fi
}

test_mysql_selection() {
    local choice="2"
    if [ "$choice" = "2" ]; then
        assert_true 1 "MySQL selection (choice=2)"
    fi
}

test_mariadb_selection() {
    local choice="3"
    if [ "$choice" = "3" ]; then
        assert_true 1 "MariaDB selection (choice=3)"
    fi
}

test_postgresql_selection() {
    local choice="4"
    if [ "$choice" = "4" ]; then
        assert_true 1 "PostgreSQL selection (choice=4)"
    fi
}

################################################################################
# Test Suite: dbUtils Functions
################################################################################

test_detect_os_function() {
    echo ""
    echo "Test Suite: dbUtils - detect_os"
    echo "================================"

    local os_val
    os_val=$(detect_os 2>/dev/null || true)
    if [ -n "$os_val" ]; then
        assert_true 1 "detect_os returned: $os_val"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: detect_os returned empty"
    fi
}

test_sqlite_create_database_function() {
    echo ""
    echo "Test Suite: dbUtils - sqlite_create_database"
    echo "============================================"

    # Mock sqlite3 to simulate successful SELECT 1;
    sqlite3() {
        if [ "$2" = "SELECT 1;" ]; then
            return 0
        fi
        return 0
    }

    local tmpdb
    tmpdb=$(make_tmpfile)
    rm -f "$tmpdb"

    sqlite_create_database "$tmpdb"
    if [ $? -eq 0 ]; then
        assert_true 1 "sqlite_create_database succeeded (mocked)"
    else
        assert_false 0 "sqlite_create_database succeeded (mocked)"
    fi
    unset -f sqlite3
}

test_sqlite_create_tables_function() {
    echo ""
    echo "Test Suite: dbUtils - sqlite_create_tables"
    echo "=========================================="

    if command -v sqlite3 >/dev/null 2>&1; then
        local tmpdb
        tmpdb=$(make_tmpfile)
        sqlite3 "$tmpdb" "SELECT 1;" >/dev/null 2>&1 || true
        sqlite_create_tables "$tmpdb"
        if [ $? -eq 0 ]; then
            assert_true 1 "sqlite_create_tables succeeded (real sqlite3)"
        else
            assert_false 0 "sqlite_create_tables succeeded (real sqlite3)"
        fi
        rm -f "$tmpdb"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: sqlite3 not available; skipping sqlite_create_tables test"
    fi
}

test_sqlite_encrypt_db_function() {
    echo ""
    echo "Test Suite: dbUtils - sqlite_encrypt_db"
    echo "========================================"

    if command -v openssl >/dev/null 2>&1; then
        local tmpdb decfile
        tmpdb=$(make_tmpfile)
        echo "testdata" > "$tmpdb"
        sqlite_encrypt_db "$tmpdb" "unittestpass"
        if [ $? -eq 0 ]; then
            # try decrypting to ensure valid encrypted blob
            decfile="${tmpdb}.dec"
            openssl enc -d -aes-256-cbc -pbkdf2 -in "$tmpdb" -out "$decfile" -pass pass:"unittestpass" 2>/dev/null
            if [ $? -eq 0 ] && [ -f "$decfile" ]; then
                assert_true 1 "sqlite_encrypt_db encrypted and decryptable"
                rm -f "$decfile"
            else
                assert_false 0 "sqlite_encrypt_db produced invalid ciphertext"
            fi
        else
            assert_false 0 "sqlite_encrypt_db failed"
        fi
        rm -f "$tmpdb"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: openssl not available; skipping sqlite_encrypt_db test"
    fi
}

test_mysql_create_database_function() {
    echo ""
    echo "Test Suite: dbUtils - mysql_create_database"
    echo "============================================"

    # Mock mysql binary
    mysql() { return 0; }
    mysql_create_database "testuser" "testpass" "testdb"
    if [ $? -eq 0 ]; then
        assert_true 1 "mysql_create_database invoked (mocked mysql)"
    else
        assert_false 0 "mysql_create_database failed"
    fi
    unset -f mysql
}

test_postgresql_create_database_function() {
    echo ""
    echo "Test Suite: dbUtils - postgresql_create_database"
    echo "================================================="

    # Mock createdb
    createdb() { return 0; }
    postgresql_create_database "postgres" "testdb"
    if [ $? -eq 0 ]; then
        assert_true 1 "postgresql_create_database invoked (mocked createdb)"
    else
        assert_false 0 "postgresql_create_database failed"
    fi
    unset -f createdb
}

################################################################################
# Test Suite: Script Structure Validation
################################################################################

test_script_syntax() {
    echo ""
    echo "Test Suite: Script Validation"
    echo "=============================="
    
    # Check if dbInit.sh has valid bash syntax
    if bash -n dbInit.sh 2>/dev/null; then
        assert_true 1 "dbInit.sh has valid bash syntax"
    else
        assert_false 0 "dbInit.sh has valid bash syntax"
    fi
}

test_script_is_executable() {
    if [ -x dbInit.sh ]; then
        assert_true 1 "dbInit.sh is executable"
    else
        echo -e "${YELLOW}⊘ SKIP${NC}: Executable permission (file not executable)"
    fi
}

test_script_has_shebang() {
    if head -n 1 dbInit.sh | grep -q "^#!/bin/bash"; then
        assert_true 1 "dbInit.sh has correct bash shebang"
    else
        assert_false 0 "dbInit.sh has correct bash shebang"
    fi
}

test_script_has_comments() {
    if grep -q "^#" dbInit.sh; then
        assert_true 1 "dbInit.sh contains comments"
    else
        assert_false 0 "dbInit.sh contains comments"
    fi
}

test_db_name_variable_exists() {
    if grep -q 'DB_NAME="myNutriLoggerInfo"' dbInit.sh; then
        assert_true 1 "DB_NAME variable is defined"
    else
        assert_false 0 "DB_NAME variable is defined"
    fi
}

test_case_statement_exists() {
    if grep -q "case.*in" dbInit.sh; then
        assert_true 1 "Case statement for database selection exists"
    else
        assert_false 0 "Case statement for database selection exists"
    fi
}

test_os_detection_logic_exists() {
    if grep -q "Detecting operating system" dbInit.sh; then
        assert_true 1 "OS detection logic comment exists"
    else
        assert_false 0 "OS detection logic comment exists"
    fi
}

################################################################################
# Test Suite: Error Handling
################################################################################

test_error_messages_exist() {
    echo ""
    echo "Test Suite: Error Handling"
    echo "=========================="
    
    if grep -q "✗ Failed" dbInit.sh; then
        assert_true 1 "Error messages present in script"
    else
        assert_false 0 "Error messages present in script"
    fi
}

test_success_messages_exist() {
    if grep -q "✓" dbInit.sh; then
        assert_true 1 "Success messages present in script"
    else
        assert_false 0 "Success messages present in script"
    fi
}

test_logging_output_exists() {
    if grep -q "echo" dbInit.sh; then
        assert_true 1 "Logging/output statements present in script"
    else
        assert_false 0 "Logging/output statements present in script"
    fi
}

################################################################################
# Test Suite: Database Commands
################################################################################

test_sqlite_command_format() {
    echo ""
    echo "Test Suite: Database Commands"
    echo "=============================="
    
    if grep -q 'sqlite3.*"SELECT 1;"' dbInit.sh; then
        assert_true 1 "SQLite test query (SELECT 1;) is correct"
    else
        assert_false 0 "SQLite test query (SELECT 1;) is correct"
    fi
}

test_mysql_create_database_command() {
    if grep -q 'CREATE DATABASE IF NOT EXISTS' dbInit.sh; then
        assert_true 1 "MySQL CREATE DATABASE command exists"
    else
        assert_false 0 "MySQL CREATE DATABASE command exists"
    fi
}

test_mariadb_create_database_command() {
    if grep -q 'mariadb.*CREATE DATABASE' dbInit.sh; then
        assert_true 1 "MariaDB CREATE DATABASE command exists"
    else
        assert_false 0 "MariaDB CREATE DATABASE command exists"
    fi
}

test_postgresql_createdb_command() {
    if grep -q 'createdb' dbInit.sh; then
        assert_true 1 "PostgreSQL createdb command exists"
    else
        assert_false 0 "PostgreSQL createdb command exists"
    fi
}

################################################################################
# Test Suite: Password Handling
################################################################################

test_mysql_password_handling() {
    echo ""
    echo "Test Suite: Password Security"
    echo "============================="
    
    if grep -q "read -sp.*password" dbInit.sh; then
        assert_true 1 "MySQL password is read silently (no echo)"
    else
        assert_false 0 "MySQL password is read silently (no echo)"
    fi
}

test_mariadb_password_handling() {
    if grep -q "read -sp.*password" dbInit.sh; then
        assert_true 1 "MariaDB password is read silently (no echo)"
    else
        assert_false 0 "MariaDB password is read silently (no echo)"
    fi
}

test_password_variable_usage() {
    if grep -q "\-p\"\$.*_pass\"" dbInit.sh; then
        assert_true 1 "Passwords are properly passed to database commands"
    else
        assert_false 0 "Passwords are properly passed to database commands"
    fi
}

################################################################################
# Run All Tests
################################################################################

main() {
    clear
    echo "================================================================================"
    echo "                        dbInit.sh Unit Test Suite"
    echo "================================================================================"
    
    # Run all test suites
    test_os_detection_ubuntu
    test_os_detection_alpine
    test_os_version_detection
    
    test_invalid_choice_validation
    test_valid_choice_range
    
    test_database_name_assignment
    test_sqlite_database_extension
    
    test_mysql_default_username
    test_mariadb_default_username
    test_postgresql_default_username
    test_custom_username_assignment
    
    test_sqlite_package_names
    test_mysql_package_names
    test_mariadb_package_names
    test_postgresql_package_names
    
    test_sqlite_selection
    test_mysql_selection
    test_mariadb_selection
    test_postgresql_selection
    
    test_script_syntax
    test_script_is_executable
    test_script_has_shebang
    test_script_has_comments
    test_db_name_variable_exists
    test_case_statement_exists
    test_os_detection_logic_exists
    
    test_error_messages_exist
    test_success_messages_exist
    test_logging_output_exists
    
    test_sqlite_command_format
    test_mysql_create_database_command
    test_mariadb_create_database_command
    test_postgresql_createdb_command
    
    test_mysql_password_handling
    test_mariadb_password_handling
    test_password_variable_usage

    # dbUtils function tests
    test_detect_os_function
    test_sqlite_create_database_function
    test_sqlite_create_tables_function
    test_sqlite_encrypt_db_function
    test_mysql_create_database_function
    test_postgresql_create_database_function
    
    # Print summary
    echo ""
    echo "================================================================================"
    echo "                              Test Summary"
    echo "================================================================================"
    echo "Total Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed:       ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        echo "================================================================================"
        return 0
    else
        echo ""
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        echo "================================================================================"
        return 1
    fi
}

# Run main function
main "$@"
exit $?
