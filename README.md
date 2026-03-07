# nutriLogger
Replacement for my manual nutrition logging workflow. I liked the control of the information and format, but disliked the steps to do it. So this is hopefully my answer.

## Database Setup

The database uses SQLite with analytical functions and views implemented in Python.

### Quick Setup

Run the initialization script:
```bash
./dbInit.sh
```
Select option 1 for SQLite. This will:
1. Create the SQLite database
2. Create all input tables
3. Setup analytical UDFs and views

### Manual Setup

If you prefer to run components separately:

1. Create database:
```bash
./dbInit.sh  # Select SQLite option
```

2. Create tables:
```bash
source dbUtils.sh
sqlite_create_tables
```

3. Setup analytical functions:
```bash
python3 sqlite_db.py
```

### Files

- `dbInit.sh` - Complete database initialization (database + tables + analytics)
- `dbUtils.sh` - Shell utilities for database creation and management
- `sqlite_db.py` - Python library with UDFs and analytical views
- `sqlite_db.py` - Python library with user-defined functions (UDFs) and analytical views
- `dbInit.sh` - Database initialization script

### Setup

1. Initialize the database:
   ```bash
   ./dbInit.sh
   ```

2. Setup analytical functions and views:
   ```bash
   python3 sqlite_db.py
   ```

The `sqlite_db.py` file contains:
- User-defined functions for BMR, TDEE, BMI, body composition calculations
- Exercise analysis functions (pHRR, METs, VO2 max)
- Analytical views that combine input data with calculations
- Utility functions for unit conversions
