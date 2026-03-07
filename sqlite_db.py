#!/usr/bin/env python3
"""
SQLite Database Library for nutriLogger
Provides user-defined functions and views for data analysis
"""

import sqlite3
import math
from datetime import datetime, date
import os

class NutriLoggerDB:
    """SQLite database handler with UDFs and views for nutrition and exercise analysis"""

    def __init__(self, db_path="myNutriLoggerInfo.db"):
        self.db_path = db_path
        self.conn = None

    def connect(self):
        """Connect to SQLite database and register UDFs"""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.execute("PRAGMA foreign_keys = ON")
        self._register_udfs()
        return self.conn

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

    def _register_udfs(self):
        """Register all user-defined functions"""

        # BMR Calculations
        self.conn.create_function("bmr_mifflin_stjeor", 4, self._bmr_mifflin_stjeor)
        self.conn.create_function("bmr_lbm", 3, self._bmr_lbm)
        self.conn.create_function("bmr_rev_hb", 4, self._bmr_rev_hb)

        # TDEE Calculation
        self.conn.create_function("calculate_tdee", 2, self._calculate_tdee)

        # Body Composition Calculations
        self.conn.create_function("calculate_bmi", 2, self._calculate_bmi)
        self.conn.create_function("calculate_ffmi", 3, self._calculate_ffmi)
        self.conn.create_function("calculate_smi", 2, self._calculate_smi)
        self.conn.create_function("calculate_sm_fm_ratio", 2, self._calculate_sm_fm_ratio)

        # Exercise Calculations
        self.conn.create_function("calculate_phrr", 4, self._calculate_phrr)
        self.conn.create_function("calculate_phrr_mets", 1, self._calculate_phrr_mets)
        self.conn.create_function("calculate_vo2max_cooper", 1, self._calculate_vo2max_cooper)
        self.conn.create_function("calculate_metsmax_peloton", 2, self._calculate_metsmax_peloton)

        # Utility Functions
        self.conn.create_function("kg_to_lb", 1, self._kg_to_lb)
        self.conn.create_function("lb_to_kg", 1, self._lb_to_kg)
        self.conn.create_function("moving_average", 3, self._moving_average)

    # BMR Functions
    @staticmethod
    def _bmr_mifflin_stjeor(weight_kg, height_cm, age_years, sex):
        """Calculate BMR using Mifflin-St Jeor equation"""
        if sex.lower() in ['m', 'male']:
            return 10 * weight_kg + 6.25 * height_cm - 5 * age_years + 5
        else:
            return 10 * weight_kg + 6.25 * height_cm - 5 * age_years - 161

    @staticmethod
    def _bmr_lbm(lean_body_mass_kg, height_cm, age_years):
        """Calculate BMR using Lean Body Mass method"""
        return 370 + (21.6 * lean_body_mass_kg)

    @staticmethod
    def _bmr_rev_hb(weight_kg, height_cm, age_years, sex):
        """Calculate BMR using Revised Harris-Benedict equation"""
        if sex.lower() in ['m', 'male']:
            return 88.362 + (13.397 * weight_kg) + (4.799 * height_cm) - (5.677 * age_years)
        else:
            return 447.593 + (9.247 * weight_kg) + (3.098 * height_cm) - (4.330 * age_years)

    @staticmethod
    def _calculate_tdee(bmr, activity_factor):
        """Calculate Total Daily Energy Expenditure"""
        return bmr * activity_factor

    # Body Composition Functions
    @staticmethod
    def _calculate_bmi(weight_kg, height_m):
        """Calculate Body Mass Index"""
        if height_m > 0:
            return weight_kg / (height_m ** 2)
        return 0

    @staticmethod
    def _calculate_ffmi(lean_mass_kg, height_m):
        """Calculate Fat-Free Mass Index"""
        if height_m > 0:
            return lean_mass_kg / (height_m ** 2)
        return 0

    @staticmethod
    def _calculate_smi(skeletal_muscle_kg, height_m):
        """Calculate Skeletal Muscle Index"""
        if height_m > 0:
            return skeletal_muscle_kg / (height_m ** 2)
        return 0

    @staticmethod
    def _calculate_sm_fm_ratio(skeletal_muscle_kg, body_fat_kg):
        """Calculate Skeletal Muscle to Fat Mass Ratio"""
        if body_fat_kg > 0:
            return skeletal_muscle_kg / body_fat_kg
        return 0

    # Exercise Functions
    @staticmethod
    def _calculate_phrr(avg_hr, rhr, max_hr, duration_minutes):
        """Calculate Percentage Heart Rate Reserve"""
        if max_hr > rhr:
            hrr = (avg_hr - rhr) / (max_hr - rhr)
            return min(max(hrr, 0), 1)  # Clamp between 0 and 1
        return 0

    @staticmethod
    def _calculate_phrr_mets(phrr):
        """Calculate METs from pHRR"""
        if phrr >= 0.85:
            return 10 + (12 - 10) * (phrr - 0.85) / (1 - 0.85)
        elif phrr >= 0.6:
            return 7 + (10 - 7) * (phrr - 0.6) / (0.85 - 0.6)
        elif phrr >= 0.4:
            return 4 + (7 - 4) * (phrr - 0.4) / (0.6 - 0.4)
        elif phrr >= 0.3:
            return 3 + (4 - 3) * (phrr - 0.3) / (0.4 - 0.3)
        else:
            return 2.8

    @staticmethod
    def _calculate_vo2max_cooper(distance_km):
        """Calculate VO2 Max using Cooper test formula"""
        return (distance_km * 1000 - 504.9) / 44.73

    @staticmethod
    def _calculate_metsmax_peloton(vo2max, weight_kg):
        """Calculate Max METs from Peloton data"""
        if weight_kg > 0:
            return vo2max / (3.5 * weight_kg / 1000)
        return 0

    # Utility Functions
    @staticmethod
    def _kg_to_lb(kg):
        """Convert kilograms to pounds"""
        return kg * 2.20462

    @staticmethod
    def _lb_to_kg(lb):
        """Convert pounds to kilograms"""
        return lb / 2.20462

    @staticmethod
    def _moving_average(value, window_size, current_date):
        """Calculate moving average (placeholder - would need window function)"""
        # This is a simplified version. In practice, you'd use window functions
        return value

    def _table_exists(self, table_name):
        """Check if a table exists in the database"""
        cursor = self.conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table_name,))
        return cursor.fetchone() is not None

    def create_views(self):
        """Create analytical views using the UDFs"""

        # Check if required tables exist
        required_tables = [
            'weight_input', 'body_composition_input', 'exercise_input',
            'blood_pressure_input', 'food_input', 'general_info'
        ]

        missing_tables = []
        for table in required_tables:
            if not self._table_exists(table):
                missing_tables.append(table)

        if missing_tables:
            print(f"Warning: Missing tables {missing_tables}. Views will be created when tables are available.")
            print("Run the database table creation first using dbUtils.sh")
            return

        views = [
            """
            CREATE VIEW IF NOT EXISTS weight_analysis AS
            SELECT
                w.id,
                w.date,
                w.weight_kg,
                kg_to_lb(w.weight_kg) as weight_lb,
                AVG(w.weight_kg) OVER (
                    ORDER BY w.date
                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                ) as weight_kg_7d_avg,
                bmr_mifflin_stjeor(
                    w.weight_kg,
                    (SELECT metric_value FROM general_info WHERE metric_name = 'height_cm'),
                    (SELECT (julianday('now') - julianday(metric_value)) / 365.25 FROM general_info WHERE metric_name = 'birth_date'),
                    (SELECT metric_value FROM general_info WHERE metric_name = 'sex')
                ) as bmr_mifflin_stjeor,
                MIN(w.weight_kg) OVER (ORDER BY w.date) as min_weight_to_date_kg,
                w.created_at
            FROM weight_input w
            """,

            """
            CREATE VIEW IF NOT EXISTS body_composition_analysis AS
            SELECT
                bc.id,
                bc.date,
                bc.weight_kg,
                bc.skeletal_muscle_kg,
                bc.body_fat,
                calculate_bmi(bc.weight_kg, (SELECT metric_value FROM general_info WHERE metric_name = 'height_m')) as bmi,
                bc.weight_kg * (1 - bc.body_fat/100) as lean_mass_kg,
                calculate_ffmi(bc.weight_kg * (1 - bc.body_fat/100), (SELECT metric_value FROM general_info WHERE metric_name = 'height_m')) as ffmi,
                calculate_smi(bc.skeletal_muscle_kg, (SELECT metric_value FROM general_info WHERE metric_name = 'height_m')) as smi,
                calculate_sm_fm_ratio(bc.skeletal_muscle_kg, bc.weight_kg * bc.body_fat/100) as sm_fm_ratio,
                bc.created_at
            FROM body_composition_input bc
            """,

            """
            CREATE VIEW IF NOT EXISTS exercise_analysis AS
            SELECT
                e.id,
                e.date,
                e.exercise_type,
                e.duration_minutes,
                e.calories_watch,
                e.avg_hr_watch,
                e.max_hr_watch,
                e.distance_watch_km,
                e.output_kj_peloton,
                e.power_w_peloton,
                -- Get most recent weight for calculations
                (SELECT w.weight_kg FROM weight_input w WHERE w.date <= e.date ORDER BY w.date DESC LIMIT 1) as weight_current_kg,
                -- Get resting HR from blood pressure data
                (SELECT MIN(bp.hr) FROM blood_pressure_input bp WHERE date(bp.datetime) <= e.date AND bp.afib = 0) as current_rhr,
                -- Calculate pHRR
                calculate_phrr(
                    e.avg_hr_watch,
                    (SELECT MIN(bp.hr) FROM blood_pressure_input bp WHERE date(bp.datetime) <= e.date AND bp.afib = 0),
                    e.max_hr_watch,
                    e.duration_minutes
                ) as phrr,
                -- Calculate METs from pHRR
                calculate_phrr_mets(calculate_phrr(
                    e.avg_hr_watch,
                    (SELECT MIN(bp.hr) FROM blood_pressure_input bp WHERE date(bp.datetime) <= e.date AND bp.afib = 0),
                    e.max_hr_watch,
                    e.duration_minutes
                )) as mets_from_phrr,
                -- VO2 Max calculations
                CASE
                    WHEN e.exercise_type = 'Outdoor Run' AND e.duration_minutes BETWEEN 11 AND 13 THEN
                        calculate_vo2max_cooper(COALESCE(e.distance_watch_km, e.distance_watch_mi * 1.60934))
                    ELSE e.vo2max_watch
                END as vo2max_calculated,
                calculate_vo2max_cooper(COALESCE(e.distance_watch_km, e.distance_watch_mi * 1.60934)) / 3.5 as vo2max_cooper,
                -- Output per minute
                CASE WHEN e.duration_minutes > 0 THEN e.output_kj_peloton / e.duration_minutes ELSE 0 END as output_per_minute,
                e.created_at
            FROM exercise_input e
            """,

            """
            CREATE VIEW IF NOT EXISTS blood_pressure_analysis AS
            SELECT
                bp.id,
                bp.datetime,
                bp.sys,
                bp.dia,
                bp.hr,
                -- 7-day moving averages
                AVG(bp.sys) OVER (
                    ORDER BY bp.datetime
                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                ) as sys_7d_avg,
                AVG(bp.dia) OVER (
                    ORDER BY bp.datetime
                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                ) as dia_7d_avg,
                AVG(bp.hr) OVER (
                    ORDER BY bp.datetime
                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                ) as hr_7d_avg,
                bp.afib,
                bp.after_meds,
                bp.created_at
            FROM blood_pressure_input bp
            WHERE bp.afib = 0  -- Only include non-afib readings for analysis
            """,

            """
            CREATE VIEW IF NOT EXISTS nutrition_analysis AS
            SELECT
                f.id,
                f.date,
                f.type,
                f.calories,
                f.protein,
                f.carbs,
                f.fat,
                f.fiber,
                f.iron,
                f.sodium,
                f.potassium,
                f.calcium,
                -- Daily totals
                SUM(f.calories) OVER (PARTITION BY f.date) as daily_calories,
                SUM(f.protein) OVER (PARTITION BY f.date) as daily_protein,
                SUM(f.carbs) OVER (PARTITION BY f.date) as daily_carbs,
                SUM(f.fat) OVER (PARTITION BY f.date) as daily_fat,
                SUM(f.fiber) OVER (PARTITION BY f.date) as daily_fiber,
                f.created_at
            FROM food_input f
            """
        ]

        for view_sql in views:
            try:
                self.conn.execute(view_sql)
            except sqlite3.Error as e:
                print(f"Error creating view: {e}")
                print(f"SQL: {view_sql}")

        self.conn.commit()

    def create_indexes(self):
        """Create indexes for better query performance"""
        indexes = [
            ("weight_input", "CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_input(date)"),
            ("exercise_input", "CREATE INDEX IF NOT EXISTS idx_exercise_date ON exercise_input(date)"),
            ("blood_pressure_input", "CREATE INDEX IF NOT EXISTS idx_bp_datetime ON blood_pressure_input(datetime)"),
            ("body_composition_input", "CREATE INDEX IF NOT EXISTS idx_body_comp_date ON body_composition_input(date)"),
            ("food_input", "CREATE INDEX IF NOT EXISTS idx_food_date ON food_input(date)"),
        ]

        for table, index_sql in indexes:
            if self._table_exists(table):
                self.conn.execute(index_sql)

        self.conn.commit()

    def setup_database(self):
        """Complete database setup with UDFs, views, and indexes"""
        self.connect()
        self.create_views()
        self.create_indexes()
        print("Database setup complete with UDFs and analytical views")

# Convenience functions for external use
def get_db_connection(db_path="myNutriLoggerInfo.db"):
    """Get a configured database connection"""
    db = NutriLoggerDB(db_path)
    return db.connect()

def setup_analysis_database(db_path="myNutriLoggerInfo.db"):
    """Setup database with all analytical functions and views"""
    db = NutriLoggerDB(db_path)
    db.setup_database()
    db.close()

if __name__ == "__main__":
    import sys
    # Use command line argument for database path, or default
    db_path = sys.argv[1] if len(sys.argv) > 1 else "myNutriLoggerInfo.db"
    setup_analysis_database(db_path)