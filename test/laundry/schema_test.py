"""Verify the actual Dart CREATE TABLE SQL with Python's real SQLite engine.
Run: python -m unittest discover -s test/laundry -p schema_test.py -v
These checks supplement Dart test doubles; Android plugin checks remain manual.
"""
from pathlib import Path
import re
import sqlite3
import tempfile
import unittest

SOURCE = (Path(__file__).resolve().parents[2] /
          'lib/features/laundry/data/database/laundry_database.dart').read_text(encoding='utf-8')
ALL_SQL = re.findall(r"await db.execute\('''(.*?)'''\);", SOURCE, re.S)
STATEMENTS = [sql for sql in ALL_SQL if sql.lstrip().startswith('CREATE TABLE')]
MIGRATIONS = [sql for sql in ALL_SQL if sql.lstrip().startswith('ALTER TABLE')]
INDEXES = re.findall(r"'(CREATE INDEX [^']+)'", SOURCE)


class LaundrySchemaTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.filename = str(Path(self.directory.name) / 'laundry.db')
        self.db = sqlite3.connect(self.filename)
        self.db.execute('PRAGMA foreign_keys = ON')
        self.assertEqual(len(STATEMENTS), 2)
        for sql in STATEMENTS + INDEXES:
            self.db.execute(sql)
        self.db.execute("INSERT INTO laundry_items(id,resident_name,service_type,created_at) VALUES(?,?,?,?)",
                        ('LD1', 'Ahmed', 'Lavage', '2026-10-15T10:00:00Z'))
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.directory.cleanup()

    def test_defaults_nullable_resident_and_reopen_persistence(self):
        self.db.close()
        self.db = sqlite3.connect(self.filename)
        self.assertEqual(self.db.execute('SELECT resident_id,status,price,price_confirmed FROM laundry_items').fetchone(),
                         (None, 'deposited', 0.0, 0))

    def test_v1_to_v2_migration_preserves_requests_prices_and_history(self):
        with sqlite3.connect(':memory:') as legacy:
            legacy.execute('PRAGMA foreign_keys = ON')
            legacy_items = re.sub(r'\s*price_confirmed[^\n]+,\n', '\n', STATEMENTS[0])
            legacy.execute(legacy_items)
            legacy.execute(STATEMENTS[1])
            legacy.execute("INSERT INTO laundry_items(id,resident_id,resident_name,service_type,price,created_at) VALUES(?,?,?,?,?,?)",
                           ('OLD', 1, 'Ahmed', 'Lavage', 15, '2026-10-15'))
            legacy.execute("INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)",
                           ('OLD', 'deposited', '2026-10-15'))
            self.assertEqual(len(MIGRATIONS), 1)
            for sql in MIGRATIONS:
                legacy.execute(sql)
            self.assertEqual(legacy.execute('SELECT id,resident_id,price,price_confirmed FROM laundry_items').fetchone(),
                             ('OLD', 1, 15.0, 0))
            self.assertEqual(legacy.execute('SELECT COUNT(*) FROM laundry_status_history').fetchone()[0], 1)

    def test_quote_flag_is_boolean(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE laundry_items SET price_confirmed = 2')

    def test_cascade_and_foreign_key(self):
        self.db.execute("INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)",
                        ('LD1', 'deposited', '2026-10-15'))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)",
                            ('MISSING', 'ready', '2026-10-15'))
        self.db.execute('DELETE FROM laundry_items WHERE id = ?', ('LD1',))
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM laundry_status_history').fetchone()[0], 0)

    def test_failed_history_rolls_back_status(self):
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute('UPDATE laundry_items SET status = ? WHERE id = ?', ('processing', 'LD1'))
                self.db.execute("INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)",
                                ('LD1', None, '2026-10-15'))
        self.assertEqual(self.db.execute('SELECT status FROM laundry_items').fetchone()[0], 'deposited')

    def test_expected_indexes_exist(self):
        names = {row[0] for row in self.db.execute("SELECT name FROM sqlite_master WHERE type = 'index'")}
        self.assertTrue({'idx_laundry_resident', 'idx_laundry_status', 'idx_laundry_history'} <= names)


if __name__ == '__main__':
    unittest.main()
