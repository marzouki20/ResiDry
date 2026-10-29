"""Real SQLite checks using the shared AppDatabase SQL; no Flutter plugin involved."""
from pathlib import Path
import re
import json
import sqlite3
import tempfile
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / 'lib/database/database.dart').read_text(encoding='utf-8')
TABLES = [sql for sql in re.findall(r"await database.execute\('''(.*?)'''\);", SOURCE, re.S)
          if sql.lstrip().startswith('CREATE TABLE')]
LAUNDRY = [sql for sql in TABLES if re.search(r'CREATE TABLE laundry_', sql)]
SHARED = [sql for sql in TABLES if sql not in LAUNDRY]
INDEXES = re.findall(r"'(CREATE INDEX [^']+)'", SOURCE)
COMPACT_SOURCE = Path('lib/features/laundry/data/laundry_compact_schema.dart').read_text(encoding='utf-8')


def compact_sql(name):
    match = re.search(r"static const " + name + r'''\s*=\s*(?:\x27\x27\x27([\s\S]*?)\x27\x27\x27|"([^"]*)")\s*;''', COMPACT_SOURCE)
    if not match:
        raise AssertionError('Missing compact schema SQL: ' + name)
    return match.group(1) or match.group(2)


class CompactLaundrySchemaTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.filename = str(Path(self.directory.name) / 'residry.db')
        self.db = sqlite3.connect(self.filename)
        self.db.execute('PRAGMA foreign_keys=ON')
        for sql in SHARED:
            self.db.execute(sql)
        self.db.execute(next(sql for sql in LAUNDRY if 'CREATE TABLE laundry_items' in sql))
        self.db.execute(compact_sql('itemsJsonSql'))
        for name in ['servicesSql', 'complaintsSql', 'eventsSql']:
            self.db.execute(compact_sql(name))
        self.db.execute("INSERT INTO users(id,name,email,password,role) VALUES(1,'Resident','r@test.invalid','test-only','Résident')")
        self.db.execute("INSERT INTO users(id,name,email,password,role) VALUES(9,'Admin','a@test.invalid','test-only','Administrateur')")
        self.db.execute("INSERT INTO laundry_items(id,resident_id,resident_name,service_type,created_at) VALUES('R',1,'Snapshot','Lavage','2026-10-29')")
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.directory.cleanup()

    def test_exactly_four_laundry_tables_and_unchanged_shared_user_schema(self):
        names = {r[0] for r in self.db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'laundry_%'")}
        self.assertEqual(names, {'laundry_items', 'laundry_services', 'laundry_complaints', 'laundry_events'})
        self.assertEqual([r[1] for r in self.db.execute('PRAGMA table_info(users)')], ['id', 'name', 'email', 'password', 'role', 'phone'])

    def test_embedded_articles_and_versioned_tariffs_survive_reopen(self):
        articles = [{'id': 'L', 'garment_type': 'Chemise', 'quantity': 3, 'weight_grams': 3000,
                     'sorting_fabric': 'cotton', 'sorting_verified_by_user_id': 9}]
        rates = [{'id': 'OLD', 'service_id': 'washing', 'unit_price_millimes': 5000, 'valid_until': '2026-10-20'},
                 {'id': 'NEW', 'service_id': 'washing', 'unit_price_millimes': 6000, 'valid_until': None}]
        self.db.execute('UPDATE laundry_items SET lines_json=?', (json.dumps(articles),))
        self.db.execute("INSERT INTO laundry_services(id,label_fr,label_en,label_ar,created_at,pricing_rules_json) VALUES('washing','Lavage','Washing','غسيل','2026-10-29',?)", (json.dumps(rates),))
        self.db.commit()
        self.db.close()
        self.db = sqlite3.connect(self.filename)
        self.assertEqual(json.loads(self.db.execute('SELECT lines_json FROM laundry_items').fetchone()[0]), articles)
        self.assertEqual(json.loads(self.db.execute('SELECT pricing_rules_json FROM laundry_services').fetchone()[0]), rates)

    def create_case(self):
        self.db.execute("INSERT INTO laundry_complaints(id,laundry_id,resident_id,reason,description,created_at,updated_at) VALUES('C','R',1,'damaged','Description suffisamment longue','2026-10-29','2026-10-29')")

    def test_common_events_keep_real_account_links_and_separate_source_identifiers(self):
        self.create_case()
        self.db.execute("INSERT INTO laundry_events(event_type,source_id,laundry_id,new_status,actor_id,created_at) VALUES('laundry_status',1,'R','deposited',1,'2026-10-29')")
        self.db.execute("INSERT INTO laundry_events(event_type,source_id,laundry_id,complaint_id,new_status,actor_id,revision,created_at) VALUES('complaint_status',1,'R','C','submitted',1,1,'2026-10-29')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE laundry_events SET actor_id=999")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE laundry_events SET revision=NULL WHERE event_type='complaint_status'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM laundry_items WHERE id='R'")
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_photo_slots_keep_size_type_and_sequence_constraints(self):
        self.create_case()
        for values in [{'photo_1': b''}, {'photo_1': 'text'}, {'photo_1': b'P' * 2097153}, {'photo_2': b'P'}]:
            column, value = next(iter(values.items()))
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(f'UPDATE laundry_complaints SET {column}=?', (value,))
        self.db.execute('UPDATE laundry_complaints SET photo_1=?,photos_metadata_json=?',
                        (b'binary fixture', json.dumps([{'id': 17, 'mime_type': 'image/png', 'created_at': '2026-10-29'}])))
        self.assertEqual(self.db.execute('SELECT photo_1 FROM laundry_complaints').fetchone()[0], b'binary fixture')


class LegacyLaundrySchemaTest(unittest.TestCase):
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

    def test_base_laundry_tables_reference_the_shared_users(self):
        tables = {r[0] for r in self.db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")}
        self.assertTrue({'users', 'residents', 'societes', 'machines', 'laundry_items', 'laundry_status_history'} <= tables)
        self.assertEqual(len(LAUNDRY), 2)
        self.assertEqual([r[1] for r in self.db.execute('PRAGMA table_info(users)')], ['id', 'name', 'email', 'password', 'role', 'phone'])
        self.assertIn('version: 14', SOURCE)

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


class LegacyAdvancedLaundrySchemaTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys=ON')
        for sql in SHARED + LAUNDRY + INDEXES:
            self.db.execute(sql)
        source = Path('lib/features/laundry/data/laundry_schema.dart').read_text(encoding='utf-8')
        for sql in re.findall(r"await db.execute\(\s*'''([\s\S]*?)'''\s*,?\s*\)", source):
            self.db.execute(sql)
        sorting_columns = re.findall(r"'(sorting_[^']+)':\s*(?:\"([^\"]*)\"|'([^']*)')", source)
        self.assertEqual(len(sorting_columns), 8)
        for name, double_quoted, single_quoted in sorting_columns:
            self.db.execute(f'ALTER TABLE laundry_request_lines ADD COLUMN {name} {double_quoted or single_quoted}')
        for _, sql in re.findall(r'''await db.execute\(\s*(['"])(CREATE (?:UNIQUE )?INDEX IF NOT EXISTS[\s\S]*?)\1\s*,?\s*\);''', source):
            if 'idx_complaint' in sql:
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

    def test_sorting_defaults_do_not_invent_historical_care_information(self):
        self.db.execute("INSERT INTO laundry_request_lines(id,laundry_id,garment_type,service_id,quantity,pricing_basis,created_at) VALUES('L','LD1','Chemise','washing',3,'per_kg','2026-10-28')")
        columns = [r[1] for r in self.db.execute('PRAGMA table_info(laundry_request_lines)') if r[1].startswith('sorting_')]
        self.assertEqual(len(columns), 8)
        self.assertEqual(self.db.execute('SELECT ' + ','.join(columns) + ' FROM laundry_request_lines').fetchone(), (None,) * 8)

    def test_sorting_constraints_and_reviewer_reference_preserve_accounts(self):
        self.db.execute("INSERT INTO laundry_request_lines(id,laundry_id,garment_type,service_id,quantity,pricing_basis,created_at) VALUES('L','LD1','Chemise','washing',3,'per_kg','2026-10-28')")
        users = self.db.execute('SELECT * FROM users').fetchall()
        for field, value in [('sorting_max_temperature_c', 0), ('sorting_max_temperature_c', 30.5),
                             ('sorting_color', 'invented'), ('sorting_wash_separately', 2)]:
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(f'UPDATE laundry_request_lines SET {field}=?', (value,))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE laundry_request_lines SET sorting_verified_by_user_id=999,sorting_verified_at='2026-10-28'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute('UPDATE laundry_request_lines SET sorting_verified_by_user_id=1')
        self.db.execute("UPDATE laundry_request_lines SET sorting_color='white',sorting_max_temperature_c=40,sorting_verified_by_user_id=1,sorting_verified_at='2026-10-28'")
        self.assertEqual(self.db.execute('SELECT * FROM users').fetchall(), users)
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def create_complaint(self):
        self.db.execute("INSERT INTO laundry_complaints(id,laundry_id,resident_id,reason,description,created_at,updated_at) VALUES('C','LD1',1,'damaged','Description suffisamment longue','2026-10-28','2026-10-28')")

    def test_complaint_ownership_duplicate_and_request_retention_constraints(self):
        self.create_complaint()
        self.assertEqual(self.db.execute('SELECT status,revision,resident_seen_revision FROM laundry_complaints').fetchone(), ('submitted', 1, 1))
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE laundry_complaints SET resident_id=999")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE laundry_complaints SET status='rejected'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO laundry_complaints(id,laundry_id,resident_id,reason,description,created_at,updated_at) VALUES('D','LD1',1,'damaged','Une autre description dupliquée','2026-10-28','2026-10-28')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("DELETE FROM laundry_items WHERE id='LD1'")
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM users').fetchone()[0], 1)

    def test_complaint_photo_constraints_and_garment_snapshot_preservation(self):
        self.db.execute("INSERT INTO laundry_request_lines(id,laundry_id,garment_type,service_id,quantity,pricing_basis,created_at) VALUES('L','LD1','Chemise','washing',3,'per_kg','2026-10-28')")
        self.create_complaint()
        self.db.execute("UPDATE laundry_complaints SET line_id='L',garment_snapshot='Chemise'")
        self.db.execute("DELETE FROM laundry_request_lines WHERE id='L'")
        self.assertEqual(self.db.execute('SELECT line_id,garment_snapshot FROM laundry_complaints').fetchone(), (None, 'Chemise'))
        sql = "INSERT INTO laundry_complaint_attachments(complaint_id,mime_type,content,created_at) VALUES('C',?,?,'2026-10-28')"
        for mime, content in [('image/png', ''), ('image/png', b''), ('image/png', b'P' * 2097153), ('video/mp4', b'P')]:
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql, (mime, content))
        self.db.execute(sql, ('image/png', b'PNG fixture: metadata constraint test only'))

    def test_complaint_decision_and_event_roll_back_together(self):
        self.create_complaint()
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute("UPDATE laundry_complaints SET status='reviewing',revision=2")
                self.db.execute("INSERT INTO laundry_complaint_events(complaint_id,old_status,new_status,actor_id,revision,created_at) VALUES('C','submitted','reviewing',999,2,'2026-10-28')")
        self.assertEqual(self.db.execute('SELECT status,revision FROM laundry_complaints').fetchone(), ('submitted', 1))
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM laundry_complaint_events').fetchone()[0], 0)


if __name__ == '__main__':
    unittest.main()
