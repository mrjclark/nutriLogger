#!/bin/bash

################################################################################
# Database Utilities Library for nutriLogger
# Provides functions to create, update, and remove database objects
# Supports: SQLite, MySQL, MariaDB, PostgreSQL
################################################################################

# Global configuration
DB_NAME="myNutriLoggerInfo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Utility Functions - OS Detection
################################################################################

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        if uname -s | grep -q "Darwin"; then
            OS="macos"
        elif uname -s | grep -q "Linux"; then
            OS="linux"
        fi
    fi
    echo "$OS"
}

################################################################################
# SQLite Database Functions
################################################################################

sqlite_create_database() {
    local db_path="${1:-$DB_NAME.db}"
    echo -e "${BLUE}[SQLite]${NC} Creating database: $db_path"
    
    if sqlite3 "$db_path" "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} SQLite database created: $db_path"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create SQLite database"
        return 1
    fi
}

sqlite_create_tables() {
    local db_path="${1:-$DB_NAME.db}"
    echo -e "${BLUE}[SQLite]${NC} Creating tables in: $db_path"
    
    sqlite3 "$db_path" << 'EOF'
-- Food Input Table
CREATE TABLE IF NOT EXISTS food_input (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    date DATE NOT NULL,
    time TIME,
    calories INTEGER,
    protein REAL,
    carbs REAL,
    fat REAL,
    fiber REAL,
    iron REAL,
    sodium INTEGER,
    potassium INTEGER,
    calcium INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Input Table
CREATE TABLE IF NOT EXISTS exercise_input (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL,
    start_time TIME,
    exercise_type TEXT NOT NULL,
    warmup_cooldown TEXT,
    calories_watch_wc INTEGER,
    duration TIME,
    avg_hr_watch INTEGER,
    max_hr_watch INTEGER,
    calories_watch INTEGER,
    distance_watch_mi REAL,
    distance_watch_km REAL,
    vo2max_watch REAL,
    calories_peloton INTEGER,
    distance_peloton REAL,
    output_kj_peloton REAL,
    power_w_peloton REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Calculated Table
CREATE TABLE IF NOT EXISTS exercise_calculated (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exercise_id INTEGER NOT NULL,
    calories_weighted_avg REAL,
    output_per_minute REAL,
    calories_output_20 REAL,
    calories_output_25 REAL,
    calories_phrr_mets REAL,
    phrr REAL,
    metsmax_peloton REAL,
    vo2max_cooper REAL,
    weight_current_kg REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exercise_id) REFERENCES exercise_input(id) ON DELETE CASCADE
);

-- Weight Input Table
CREATE TABLE IF NOT EXISTS weight_input (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL UNIQUE,
    time TIME,
    weight_kg REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Weight Calculated Table
CREATE TABLE IF NOT EXISTS weight_calculated (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight_id INTEGER NOT NULL UNIQUE,
    weight_lb REAL,
    weight_kg_7davg REAL,
    bmr_mifflin_stjeor REAL,
    bmr_lbm REAL,
    bmr_rev_hb REAL,
    tdee REAL,
    min_weight_to_date_kg REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (weight_id) REFERENCES weight_input(id) ON DELETE CASCADE
);

-- Body Composition Input Table
CREATE TABLE IF NOT EXISTS body_composition_input (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL UNIQUE,
    weight_kg REAL NOT NULL,
    skeletal_muscle_kg REAL,
    body_fat REAL,
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Body Composition Calculated Table
CREATE TABLE IF NOT EXISTS body_composition_calculated (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    body_id INTEGER NOT NULL UNIQUE,
    bmi REAL,
    lean_mass REAL,
    ffmi REAL,
    smi REAL,
    sm_fm_ratio REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (body_id) REFERENCES body_composition_input(id) ON DELETE CASCADE
);

-- Blood Pressure Input Table
CREATE TABLE IF NOT EXISTS blood_pressure_input (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    datetime DATETIME NOT NULL UNIQUE,
    sys INTEGER NOT NULL,
    dia INTEGER NOT NULL,
    hr INTEGER,
    after_meds BOOLEAN,
    location TEXT,
    from_source TEXT,
    afib BOOLEAN,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood Pressure Calculated Table
CREATE TABLE IF NOT EXISTS blood_pressure_calculated (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bp_id INTEGER NOT NULL UNIQUE,
    sys7day REAL,
    dia7day REAL,
    hr7day REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bp_id) REFERENCES blood_pressure_input(id) ON DELETE CASCADE
);

-- Workout Plan Table
CREATE TABLE IF NOT EXISTS workout_plan (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    week INTEGER,
    day TEXT NOT NULL,
    exercise_type TEXT NOT NULL,
    expected_avg_max_hr_percent REAL,
    exercise_name TEXT NOT NULL,
    sets INTEGER,
    min_reps INTEGER,
    max_reps INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- General Info Table
CREATE TABLE IF NOT EXISTS general_info (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT NOT NULL UNIQUE,
    metric_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Motivation Mantras Table
CREATE TABLE IF NOT EXISTS motivation_mantras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol TEXT UNIQUE,
    ritual TEXT NOT NULL,
    meaning TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Motivation Quotes Table
CREATE TABLE IF NOT EXISTS motivation_quotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quote TEXT NOT NULL,
    author TEXT,
    meaning TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dashboard BP Table
CREATE TABLE IF NOT EXISTS dashboard_bp (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric TEXT NOT NULL UNIQUE,
    status TEXT,
    today REAL,
    three_day_avg REAL,
    seven_day_avg REAL,
    goal_lower REAL,
    goal_higher REAL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dashboard Nutrition Table
CREATE TABLE IF NOT EXISTS dashboard_nutrition (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric TEXT NOT NULL UNIQUE,
    status TEXT,
    today REAL,
    three_day_avg REAL,
    seven_day_avg REAL,
    goal_lower REAL,
    goal_higher REAL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_food_date ON food_input(date);
CREATE INDEX IF NOT EXISTS idx_exercise_date ON exercise_input(date);
CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_input(date);
CREATE INDEX IF NOT EXISTS idx_bp_datetime ON blood_pressure_input(datetime);
CREATE INDEX IF NOT EXISTS idx_body_comp_date ON body_composition_input(date);
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} SQLite tables created successfully"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create SQLite tables"
        return 1
    fi
}

sqlite_drop_all_objects() {
    local db_path="${1:-$DB_NAME.db}"
    echo -e "${BLUE}[SQLite]${NC} Dropping all tables from: $db_path"
    
    sqlite3 "$db_path" << 'EOF'
DROP TABLE IF EXISTS dashboard_nutrition;
DROP TABLE IF EXISTS dashboard_bp;
DROP TABLE IF EXISTS motivation_quotes;
DROP TABLE IF EXISTS motivation_mantras;
DROP TABLE IF EXISTS general_info;
DROP TABLE IF EXISTS workout_plan;
DROP TABLE IF EXISTS blood_pressure_calculated;
DROP TABLE IF EXISTS blood_pressure_input;
DROP TABLE IF EXISTS body_composition_calculated;
DROP TABLE IF EXISTS body_composition_input;
DROP TABLE IF EXISTS weight_calculated;
DROP TABLE IF EXISTS weight_input;
DROP TABLE IF EXISTS exercise_calculated;
DROP TABLE IF EXISTS exercise_input;
DROP TABLE IF EXISTS food_input;
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All SQLite tables dropped"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to drop SQLite tables"
        return 1
    fi
}

################################################################################
# SQLite Encryption Helpers
################################################################################

sqlite_encrypt_db() {
    local db_path="${1:-$DB_NAME.db}"
    local passphrase="${2-}"
    local tmp_enc="${db_path}.enc"

    if [ ! -f "$db_path" ]; then
        echo -e "${RED}✗${NC} Database file not found: $db_path"
        return 1
    fi

    if ! command -v openssl >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} 'openssl' not found in PATH. Please install openssl to continue."
        return 2
    fi

    if [ -z "$passphrase" ]; then
        echo -n "Enter passphrase to encrypt the database: "
        read -s passphrase
        echo
        echo -n "Confirm passphrase: "
        read -s passphrase_confirm
        echo
        if [ "$passphrase" != "$passphrase_confirm" ]; then
            echo -e "${RED}✗${NC} Passphrases do not match"
            return 3
        fi
    fi

    echo -e "${BLUE}[SQLite]${NC} Encrypting database: $db_path"

    # Use OpenSSL AES-256-CBC with PBKDF2. The passphrase is provided on the command line
    # for simplicity; avoid on shared systems if process-list exposure is a concern.
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$db_path" -out "$tmp_enc" -pass pass:"$passphrase"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗${NC} OpenSSL failed to encrypt the database"
        [ -f "$tmp_enc" ] && rm -f "$tmp_enc"
        return 4
    fi

    # Replace original with encrypted file and restrict permissions
    mv "$tmp_enc" "$db_path"
    chmod 600 "$db_path"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Database encrypted (file replaced): $db_path"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to finalize encrypted database"
        return 5
    fi
}

################################################################################
# MySQL/MariaDB Database Functions
################################################################################

mysql_create_database() {
    local user="${1:-root}"
    local password="${2}"
    local db_name="${3:-$DB_NAME}"
    
    echo -e "${BLUE}[MySQL/MariaDB]${NC} Creating database: $db_name"
    
    if [ -z "$password" ]; then
        mysql -u "$user" -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    else
        mysql -u "$user" -p"$password" -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Database created: $db_name"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create database"
        return 1
    fi
}

mysql_create_tables() {
    local user="${1:-root}"
    local password="${2}"
    local db_name="${3:-$DB_NAME}"
    
    echo -e "${BLUE}[MySQL/MariaDB]${NC} Creating tables in: $db_name"
    
    local sql_script=$(cat << 'EOSQL'
-- Food Input Table
CREATE TABLE IF NOT EXISTS food_input (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    time TIME,
    calories INT,
    protein DECIMAL(6,2),
    carbs DECIMAL(6,2),
    fat DECIMAL(6,2),
    fiber DECIMAL(6,2),
    iron DECIMAL(6,2),
    sodium INT,
    potassium INT,
    calcium INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exercise Input Table
CREATE TABLE IF NOT EXISTS exercise_input (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    start_time TIME,
    exercise_type VARCHAR(100) NOT NULL,
    warmup_cooldown VARCHAR(50),
    calories_watch_wc INT,
    duration TIME,
    avg_hr_watch INT,
    max_hr_watch INT,
    calories_watch INT,
    distance_watch_mi DECIMAL(6,2),
    distance_watch_km DECIMAL(6,2),
    vo2max_watch DECIMAL(5,2),
    calories_peloton INT,
    distance_peloton DECIMAL(6,2),
    output_kj_peloton DECIMAL(8,2),
    power_w_peloton INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exercise Calculated Table
CREATE TABLE IF NOT EXISTS exercise_calculated (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exercise_id INT NOT NULL,
    calories_weighted_avg DECIMAL(8,2),
    output_per_minute DECIMAL(8,4),
    calories_output_20 DECIMAL(8,2),
    calories_output_25 DECIMAL(8,2),
    calories_phrr_mets DECIMAL(8,2),
    phrr DECIMAL(5,3),
    metsmax_peloton DECIMAL(5,2),
    vo2max_cooper DECIMAL(5,2),
    weight_current_kg DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exercise_id) REFERENCES exercise_input(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Weight Input Table
CREATE TABLE IF NOT EXISTS weight_input (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    time TIME,
    weight_kg DECIMAL(6,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Weight Calculated Table
CREATE TABLE IF NOT EXISTS weight_calculated (
    id INT AUTO_INCREMENT PRIMARY KEY,
    weight_id INT NOT NULL UNIQUE,
    weight_lb DECIMAL(6,2),
    weight_kg_7davg DECIMAL(6,2),
    bmr_mifflin_stjeor DECIMAL(8,2),
    bmr_lbm DECIMAL(8,2),
    bmr_rev_hb DECIMAL(8,2),
    tdee DECIMAL(8,2),
    min_weight_to_date_kg DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (weight_id) REFERENCES weight_input(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Body Composition Input Table
CREATE TABLE IF NOT EXISTS body_composition_input (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    weight_kg DECIMAL(6,2) NOT NULL,
    skeletal_muscle_kg DECIMAL(6,2),
    body_fat DECIMAL(5,2),
    source VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Body Composition Calculated Table
CREATE TABLE IF NOT EXISTS body_composition_calculated (
    id INT AUTO_INCREMENT PRIMARY KEY,
    body_id INT NOT NULL UNIQUE,
    bmi DECIMAL(5,2),
    lean_mass DECIMAL(6,2),
    ffmi DECIMAL(5,2),
    smi DECIMAL(5,2),
    sm_fm_ratio DECIMAL(5,3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (body_id) REFERENCES body_composition_input(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blood Pressure Input Table
CREATE TABLE IF NOT EXISTS blood_pressure_input (
    id INT AUTO_INCREMENT PRIMARY KEY,
    datetime DATETIME NOT NULL UNIQUE,
    sys INT NOT NULL,
    dia INT NOT NULL,
    hr INT,
    after_meds BOOLEAN,
    location VARCHAR(100),
    from_source VARCHAR(100),
    afib BOOLEAN,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_datetime (datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blood Pressure Calculated Table
CREATE TABLE IF NOT EXISTS blood_pressure_calculated (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bp_id INT NOT NULL UNIQUE,
    sys7day DECIMAL(6,2),
    dia7day DECIMAL(6,2),
    hr7day DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bp_id) REFERENCES blood_pressure_input(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Workout Plan Table
CREATE TABLE IF NOT EXISTS workout_plan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    week INT,
    day VARCHAR(20) NOT NULL,
    exercise_type VARCHAR(100) NOT NULL,
    expected_avg_max_hr_percent DECIMAL(5,2),
    exercise_name VARCHAR(200) NOT NULL,
    sets INT,
    min_reps INT,
    max_reps INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- General Info Table
CREATE TABLE IF NOT EXISTS general_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL UNIQUE,
    metric_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Motivation Mantras Table
CREATE TABLE IF NOT EXISTS motivation_mantras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(10) UNIQUE,
    ritual TEXT NOT NULL,
    meaning TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Motivation Quotes Table
CREATE TABLE IF NOT EXISTS motivation_quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quote TEXT NOT NULL,
    author VARCHAR(200),
    meaning TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dashboard BP Table
CREATE TABLE IF NOT EXISTS dashboard_bp (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(50),
    today DECIMAL(8,2),
    three_day_avg DECIMAL(8,2),
    seven_day_avg DECIMAL(8,2),
    goal_lower DECIMAL(8,2),
    goal_higher DECIMAL(8,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dashboard Nutrition Table
CREATE TABLE IF NOT EXISTS dashboard_nutrition (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(50),
    today DECIMAL(8,2),
    three_day_avg DECIMAL(8,2),
    seven_day_avg DECIMAL(8,2),
    goal_lower DECIMAL(8,2),
    goal_higher DECIMAL(8,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOSQL
)

    if [ -z "$password" ]; then
        mysql -u "$user" "$db_name" << EOF
$sql_script
EOF
    else
        mysql -u "$user" -p"$password" "$db_name" << EOF
$sql_script
EOF
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} MySQL/MariaDB tables created successfully"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create MySQL/MariaDB tables"
        return 1
    fi
}

mysql_drop_all_objects() {
    local user="${1:-root}"
    local password="${2}"
    local db_name="${3:-$DB_NAME}"
    
    echo -e "${BLUE}[MySQL/MariaDB]${NC} Dropping all tables from: $db_name"
    
    if [ -z "$password" ]; then
        mysql -u "$user" "$db_name" -e "
            SET FOREIGN_KEY_CHECKS=0;
            DROP TABLE IF EXISTS dashboard_nutrition;
            DROP TABLE IF EXISTS dashboard_bp;
            DROP TABLE IF EXISTS motivation_quotes;
            DROP TABLE IF EXISTS motivation_mantras;
            DROP TABLE IF EXISTS general_info;
            DROP TABLE IF EXISTS workout_plan;
            DROP TABLE IF EXISTS blood_pressure_calculated;
            DROP TABLE IF EXISTS blood_pressure_input;
            DROP TABLE IF EXISTS body_composition_calculated;
            DROP TABLE IF EXISTS body_composition_input;
            DROP TABLE IF EXISTS weight_calculated;
            DROP TABLE IF EXISTS weight_input;
            DROP TABLE IF EXISTS exercise_calculated;
            DROP TABLE IF EXISTS exercise_input;
            DROP TABLE IF EXISTS food_input;
            SET FOREIGN_KEY_CHECKS=1;
        " 2>/dev/null
    else
        mysql -u "$user" -p"$password" "$db_name" -e "
            SET FOREIGN_KEY_CHECKS=0;
            DROP TABLE IF EXISTS dashboard_nutrition;
            DROP TABLE IF EXISTS dashboard_bp;
            DROP TABLE IF EXISTS motivation_quotes;
            DROP TABLE IF EXISTS motivation_mantras;
            DROP TABLE IF EXISTS general_info;
            DROP TABLE IF EXISTS workout_plan;
            DROP TABLE IF EXISTS blood_pressure_calculated;
            DROP TABLE IF EXISTS blood_pressure_input;
            DROP TABLE IF EXISTS body_composition_calculated;
            DROP TABLE IF EXISTS body_composition_input;
            DROP TABLE IF EXISTS weight_calculated;
            DROP TABLE IF EXISTS weight_input;
            DROP TABLE IF EXISTS exercise_calculated;
            DROP TABLE IF EXISTS exercise_input;
            DROP TABLE IF EXISTS food_input;
            SET FOREIGN_KEY_CHECKS=1;
        " 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All MySQL/MariaDB tables dropped"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to drop MySQL/MariaDB tables"
        return 1
    fi
}

################################################################################
# PostgreSQL Database Functions
################################################################################

postgresql_create_database() {
    local user="${1:-postgres}"
    local db_name="${2:-$DB_NAME}"
    
    echo -e "${BLUE}[PostgreSQL]${NC} Creating database: $db_name"
    
    createdb -U "$user" -E UTF8 -L en_US.UTF-8 "$db_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} PostgreSQL database created: $db_name"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create PostgreSQL database"
        return 1
    fi
}

postgresql_create_tables() {
    local user="${1:-postgres}"
    local db_name="${2:-$DB_NAME}"
    
    echo -e "${BLUE}[PostgreSQL]${NC} Creating tables in: $db_name"
    
    psql -U "$user" -d "$db_name" << 'EOF' 2>/dev/null
-- Food Input Table
CREATE TABLE IF NOT EXISTS food_input (
    id SERIAL PRIMARY KEY,
    type VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    time TIME,
    calories INTEGER,
    protein DECIMAL(6,2),
    carbs DECIMAL(6,2),
    fat DECIMAL(6,2),
    fiber DECIMAL(6,2),
    iron DECIMAL(6,2),
    sodium INTEGER,
    potassium INTEGER,
    calcium INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Input Table
CREATE TABLE IF NOT EXISTS exercise_input (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    start_time TIME,
    exercise_type VARCHAR(100) NOT NULL,
    warmup_cooldown VARCHAR(50),
    calories_watch_wc INTEGER,
    duration TIME,
    avg_hr_watch INTEGER,
    max_hr_watch INTEGER,
    calories_watch INTEGER,
    distance_watch_mi DECIMAL(6,2),
    distance_watch_km DECIMAL(6,2),
    vo2max_watch DECIMAL(5,2),
    calories_peloton INTEGER,
    distance_peloton DECIMAL(6,2),
    output_kj_peloton DECIMAL(8,2),
    power_w_peloton INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Calculated Table
CREATE TABLE IF NOT EXISTS exercise_calculated (
    id SERIAL PRIMARY KEY,
    exercise_id INTEGER NOT NULL REFERENCES exercise_input(id) ON DELETE CASCADE,
    calories_weighted_avg DECIMAL(8,2),
    output_per_minute DECIMAL(8,4),
    calories_output_20 DECIMAL(8,2),
    calories_output_25 DECIMAL(8,2),
    calories_phrr_mets DECIMAL(8,2),
    phrr DECIMAL(5,3),
    metsmax_peloton DECIMAL(5,2),
    vo2max_cooper DECIMAL(5,2),
    weight_current_kg DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Weight Input Table
CREATE TABLE IF NOT EXISTS weight_input (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    time TIME,
    weight_kg DECIMAL(6,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Weight Calculated Table
CREATE TABLE IF NOT EXISTS weight_calculated (
    id SERIAL PRIMARY KEY,
    weight_id INTEGER NOT NULL UNIQUE REFERENCES weight_input(id) ON DELETE CASCADE,
    weight_lb DECIMAL(6,2),
    weight_kg_7davg DECIMAL(6,2),
    bmr_mifflin_stjeor DECIMAL(8,2),
    bmr_lbm DECIMAL(8,2),
    bmr_rev_hb DECIMAL(8,2),
    tdee DECIMAL(8,2),
    min_weight_to_date_kg DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Body Composition Input Table
CREATE TABLE IF NOT EXISTS body_composition_input (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    weight_kg DECIMAL(6,2) NOT NULL,
    skeletal_muscle_kg DECIMAL(6,2),
    body_fat DECIMAL(5,2),
    source VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Body Composition Calculated Table
CREATE TABLE IF NOT EXISTS body_composition_calculated (
    id SERIAL PRIMARY KEY,
    body_id INTEGER NOT NULL UNIQUE REFERENCES body_composition_input(id) ON DELETE CASCADE,
    bmi DECIMAL(5,2),
    lean_mass DECIMAL(6,2),
    ffmi DECIMAL(5,2),
    smi DECIMAL(5,2),
    sm_fm_ratio DECIMAL(5,3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood Pressure Input Table
CREATE TABLE IF NOT EXISTS blood_pressure_input (
    id SERIAL PRIMARY KEY,
    datetime TIMESTAMP NOT NULL UNIQUE,
    sys INTEGER NOT NULL,
    dia INTEGER NOT NULL,
    hr INTEGER,
    after_meds BOOLEAN,
    location VARCHAR(100),
    from_source VARCHAR(100),
    afib BOOLEAN,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood Pressure Calculated Table
CREATE TABLE IF NOT EXISTS blood_pressure_calculated (
    id SERIAL PRIMARY KEY,
    bp_id INTEGER NOT NULL UNIQUE REFERENCES blood_pressure_input(id) ON DELETE CASCADE,
    sys7day DECIMAL(6,2),
    dia7day DECIMAL(6,2),
    hr7day DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workout Plan Table
CREATE TABLE IF NOT EXISTS workout_plan (
    id SERIAL PRIMARY KEY,
    week INTEGER,
    day VARCHAR(20) NOT NULL,
    exercise_type VARCHAR(100) NOT NULL,
    expected_avg_max_hr_percent DECIMAL(5,2),
    exercise_name VARCHAR(200) NOT NULL,
    sets INTEGER,
    min_reps INTEGER,
    max_reps INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- General Info Table
CREATE TABLE IF NOT EXISTS general_info (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL UNIQUE,
    metric_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Motivation Mantras Table
CREATE TABLE IF NOT EXISTS motivation_mantras (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10) UNIQUE,
    ritual TEXT NOT NULL,
    meaning TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Motivation Quotes Table
CREATE TABLE IF NOT EXISTS motivation_quotes (
    id SERIAL PRIMARY KEY,
    quote TEXT NOT NULL,
    author VARCHAR(200),
    meaning TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dashboard BP Table
CREATE TABLE IF NOT EXISTS dashboard_bp (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(50),
    today DECIMAL(8,2),
    three_day_avg DECIMAL(8,2),
    seven_day_avg DECIMAL(8,2),
    goal_lower DECIMAL(8,2),
    goal_higher DECIMAL(8,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dashboard Nutrition Table
CREATE TABLE IF NOT EXISTS dashboard_nutrition (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(50),
    today DECIMAL(8,2),
    three_day_avg DECIMAL(8,2),
    seven_day_avg DECIMAL(8,2),
    goal_lower DECIMAL(8,2),
    goal_higher DECIMAL(8,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_food_date ON food_input(date);
CREATE INDEX IF NOT EXISTS idx_exercise_date ON exercise_input(date);
CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_input(date);
CREATE INDEX IF NOT EXISTS idx_bp_datetime ON blood_pressure_input(datetime);
CREATE INDEX IF NOT EXISTS idx_body_comp_date ON body_composition_input(date);
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} PostgreSQL tables created successfully"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create PostgreSQL tables"
        return 1
    fi
}

postgresql_drop_all_objects() {
    local user="${1:-postgres}"
    local db_name="${2:-$DB_NAME}"
    
    echo -e "${BLUE}[PostgreSQL]${NC} Dropping all tables from: $db_name"
    
    psql -U "$user" -d "$db_name" << 'EOF' 2>/dev/null
DROP TABLE IF EXISTS dashboard_nutrition CASCADE;
DROP TABLE IF EXISTS dashboard_bp CASCADE;
DROP TABLE IF EXISTS motivation_quotes CASCADE;
DROP TABLE IF EXISTS motivation_mantras CASCADE;
DROP TABLE IF EXISTS general_info CASCADE;
DROP TABLE IF EXISTS workout_plan CASCADE;
DROP TABLE IF EXISTS blood_pressure_calculated CASCADE;
DROP TABLE IF EXISTS blood_pressure_input CASCADE;
DROP TABLE IF EXISTS body_composition_calculated CASCADE;
DROP TABLE IF EXISTS body_composition_input CASCADE;
DROP TABLE IF EXISTS weight_calculated CASCADE;
DROP TABLE IF EXISTS weight_input CASCADE;
DROP TABLE IF EXISTS exercise_calculated CASCADE;
DROP TABLE IF EXISTS exercise_input CASCADE;
DROP TABLE IF EXISTS food_input CASCADE;
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All PostgreSQL tables dropped"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to drop PostgreSQL tables"
        return 1
    fi
}

################################################################################
# Generic Database Functions
################################################################################

create_all_databases() {
    local db_type="$1"
    
    echo -e "${YELLOW}Creating all databases for $db_type...${NC}\n"
    
    case $db_type in
        sqlite)
            sqlite_create_database && sqlite_create_tables
            ;;
        mysql|mariadb)
            local user="${2:-root}"
            local password="${3}"
            mysql_create_database "$user" "$password" && mysql_create_tables "$user" "$password"
            ;;
        postgresql)
            local user="${2:-postgres}"
            postgresql_create_database "$user" && postgresql_create_tables "$user"
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown database type: $db_type"
            return 1
            ;;
    esac
}

drop_all_databases() {
    local db_type="$1"
    
    echo -e "${YELLOW}Dropping all database objects for $db_type...${NC}\n"
    
    case $db_type in
        sqlite)
            sqlite_drop_all_objects
            ;;
        mysql|mariadb)
            local user="${2:-root}"
            local password="${3}"
            mysql_drop_all_objects "$user" "$password"
            ;;
        postgresql)
            local user="${2:-postgres}"
            postgresql_drop_all_objects "$user"
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown database type: $db_type"
            return 1
            ;;
    esac
}

################################################################################
# Utility Functions - Show Tables
################################################################################

show_sqlite_tables() {
    local db_path="${1:-$DB_NAME.db}"
    echo -e "${BLUE}[SQLite]${NC} Tables in: $db_path"
    sqlite3 "$db_path" ".tables"
}

show_mysql_tables() {
    local user="${1:-root}"
    local password="${2}"
    local db_name="${3:-$DB_NAME}"
    
    echo -e "${BLUE}[MySQL/MariaDB]${NC} Tables in: $db_name"
    if [ -z "$password" ]; then
        mysql -u "$user" "$db_name" -e "SHOW TABLES;" 2>/dev/null
    else
        mysql -u "$user" -p"$password" "$db_name" -e "SHOW TABLES;" 2>/dev/null
    fi
}

show_postgresql_tables() {
    local user="${1:-postgres}"
    local db_name="${2:-$DB_NAME}"
    
    echo -e "${BLUE}[PostgreSQL]${NC} Tables in: $db_name"
    psql -U "$user" -d "$db_name" -c "\dt" 2>/dev/null
}

################################################################################
# Export utility functions for sourcing
################################################################################

export -f detect_os
export -f sqlite_create_database sqlite_create_tables sqlite_drop_all_objects
export -f mysql_create_database mysql_create_tables mysql_drop_all_objects
export -f postgresql_create_database postgresql_create_tables postgresql_drop_all_objects
export -f create_all_databases drop_all_databases
export -f show_sqlite_tables show_mysql_tables show_postgresql_tables
