"""Real SQLite checks using the shared AppDatabase SQL; no Flutter plugin involved."""
from pathlib import Path
import re
import sqlite3
import tempfile
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / 'lib/database/database.dart').read_text(encoding='utf-8')
TABLES = [sql for sql in re.findall(r"await database.execute\('''(.*?)'''\);", SOURCE, re.S)
          if sql.lstrip().startswith('CREATE TABLE')]
LAUNDRY = [sql for sql in TABLES if re.search(r'CREATE TABLE laundry_', sql)]
SHARED = [sql for sql in TABLES if sql not in LAUNDRY]
INDEXES = re.findall(r"'(CREATE INDEX [^']+)'", SOURCE)


class LaundrySchemaTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.filename = str(Path(self.directory.name) / 'residry.db')
        self.db = sqlite3.connect(self.filename)
        self.db.execute('PRAGMA foreign_keys = ON')
        for sql in TABLES + INDEXES:
            self.db.execute(sql)
        self.db.execute('INSERT INTO users(id,name,email,password,role) VALUES(?,?,?,?,?)',
                        (1, 'Resident fixture', 'fixture@test.invalid', 'test-only', 'Résident'))
        self.db.execute('INSERT INTO laundry_items(id,resident_id,resident_name,service_type,created_at) VALUES(?,?,?,?,?)',
                        ('LD1', 1, 'Historical name', 'Lavage', '2026-10-16T00:00:00Z'))
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.directory.cleanup()

    def test_shared_database_contains_one_users_table_and_two_laundry_tables(self):
        tables = {r[0] for r in self.db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")}
        self.assertTrue({'users', 'residents', 'societes', 'machines', 'laundry_items', 'laundry_status_history'} <= tables)
        self.assertEqual(len(LAUNDRY), 2)
        self.assertEqual([r[1] for r in self.db.execute('PRAGMA table_info(users)')], ['id', 'name', 'email', 'password', 'role', 'phone'])
        self.assertIn('version: 11', SOURCE)

    def test_defaults_and_reopen_persistence(self):
        self.db.close()
        self.db = sqlite3.connect(self.filename)
        self.assertEqual(self.db.execute('SELECT resident_id,status,price,price_confirmed FROM laundry_items').fetchone(),
                         (1, 'deposited', 0.0, 0))

    def test_resident_and_author_foreign_keys_use_central_users(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE laundry_items SET resident_id = ?', (777777,))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('INSERT INTO laundry_status_history(laundry_id,new_status,changed_by_user_id,changed_at) VALUES(?,?,?,?)',
                            ('LD1', 'ready', 777777, '2026-10-16'))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('DELETE FROM users WHERE id = 1')
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_history_foreign_key_and_delete_cascade(self):
        self.db.execute('INSERT INTO laundry_status_history(laundry_id,new_status,changed_by_user_id,changed_at) VALUES(?,?,?,?)',
                        ('LD1', 'deposited', 1, '2026-10-16'))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)', ('MISSING', 'ready', '2026-10-16'))
        self.db.execute('DELETE FROM laundry_items WHERE id = ?', ('LD1',))
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM laundry_status_history').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM users').fetchone()[0], 1)

    def test_legacy_can_remain_unassigned_without_verification_columns(self):
        self.db.execute('INSERT INTO laundry_items(id,resident_name,service_type,price,created_at) VALUES(?,?,?,?,?)',
                        ('OLD', 'Preserved legacy name', 'Lavage', 17, '2026-10-15'))
        self.assertIsNone(self.db.execute("SELECT resident_id FROM laundry_items WHERE id='OLD'").fetchone()[0])
        names = {r[1] for r in self.db.execute('PRAGMA table_info(laundry_items)')}
        self.assertNotIn('resident_link_verified', names)
        self.assertEqual(self.db.execute('SELECT id FROM laundry_items WHERE resident_id=1').fetchall(), [('LD1',)])

    def test_quote_flag_and_rollback(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE laundry_items SET price_confirmed = 2')
        self.db.rollback()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute('UPDATE laundry_items SET status=? WHERE id=?', ('processing', 'LD1'))
                self.db.execute('INSERT INTO laundry_status_history(laundry_id,new_status,changed_at) VALUES(?,?,?)', ('LD1', None, '2026-10-16'))
        self.assertEqual(self.db.execute('SELECT status FROM laundry_items').fetchone()[0], 'deposited')

    def test_version5_shared_rows_survive_adding_laundry_tables(self):
        with sqlite3.connect(':memory:') as previous:
            for sql in SHARED:
                previous.execute(sql)
            previous.execute('INSERT INTO users(name,email,password,role) VALUES(?,?,?,?)',
                             ('Existing account', 'existing@test.invalid', 'unchanged', 'Administrateur'))
            original = previous.execute('SELECT * FROM users').fetchall()
            for sql in LAUNDRY + INDEXES:
                previous.execute(sql)
            self.assertEqual(previous.execute('SELECT * FROM users').fetchall(), original)
            self.assertEqual(previous.execute('SELECT COUNT(*) FROM laundry_items').fetchone()[0], 0)

    def test_expected_indexes_exist(self):
        names = {r[0] for r in self.db.execute("SELECT name FROM sqlite_master WHERE type='index'")}
        self.assertTrue({'idx_laundry_resident', 'idx_laundry_status', 'idx_laundry_history'} <= names)


class AdvancedLaundrySchemaTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys=ON')
        for sql in SHARED + LAUNDRY + INDEXES:
            self.db.execute(sql)
        source = Path('lib/features/laundry/data/laundry_schema.dart').read_text(encoding='utf-8')
        for sql in re.findall(r"await db.execute\('''([\s\S]*?)'''\)", source):
            self.db.execute(sql)
        self.db.execute('INSERT INTO users(id,name,email,password,role) VALUES(1,?,?,?,?)',
                        ('Account', 'account@test.invalid', 'unchanged', 'Administrateur'))
        self.db.execute("INSERT INTO laundry_service_types VALUES('washing','Lavage','Washing','Laundry',1,'2026-10-24')")
        self.db.execute("INSERT INTO laundry_items(id,resident_id,resident_name,service_type,created_at) VALUES('LD1',1,'Account','Lavage','2026-10-24')")
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_rate_requires_real_actor_and_valid_amount(self):
        sql = 'INSERT INTO laundry_pricing_rules(id,service_id,pricing_basis,unit_price_millimes,created_by_user_id,valid_from,created_at) VALUES(?,?,?,?,?,?,?)'
        for basis, price, author in [('per_kg', -1, 1), ('invalid', 5000, 1), ('per_kg', 5000, 999)]:
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql, ('RATE', 'washing', basis, price, author, '2026-10-24', '2026-10-24'))
        self.db.execute(sql, ('RATE', 'washing', 'per_kg', 5000, 1, '2026-10-24', '2026-10-24'))
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_line_constraints_and_cascade_leave_accounts_intact(self):
        sql = 'INSERT INTO laundry_request_lines(id,laundry_id,garment_type,service_id,quantity,pricing_basis,created_at) VALUES(?,?,?,?,?,?,?)'
        for parent, garment, quantity in [('MISSING', 'Chemise', 3), ('LD1', '', 3), ('LD1', 'Chemise', 0)]:
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql, ('LINE', parent, garment, 'washing', quantity, 'per_kg', '2026-10-24'))
        self.db.execute(sql, ('LINE', 'LD1', 'Chemise', 'washing', 3, 'per_kg', '2026-10-24'))
        self.db.execute("DELETE FROM laundry_items WHERE id='LD1'")
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM laundry_request_lines').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM users').fetchone()[0], 1)


if __name__ == '__main__':
    unittest.main()
