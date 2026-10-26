"""Check actual migration/repository SQL with SQLite. ArkData needs native tests too."""
from pathlib import Path
import re
import sqlite3
import tempfile

root = Path(__file__).resolve().parents[1]
schema = (root / 'entry/src/main/ets/data/migration/Schema.ets').read_text()
repository = (root / 'entry/src/main/ets/data/repository/RdbActivityRepository.ets').read_text()
def statements(version):
    section = re.search(rf'export const SCHEMA_V{version}: string\[\] = \[(.*?)\n\];',schema,re.S).group(1)
    return [a or b for a,b in re.findall(r'`([^`]+)`|\x27([^\x27]+)\x27',section)]
upsert = re.search(r'await transaction.execute\(`(INSERT INTO activities.*?)`,',repository,re.S).group(1)
passed = 0
def check(name, callback):
    global passed
    callback();passed += 1;print('PASS',name)
with tempfile.TemporaryDirectory(prefix='shiji-schema-') as directory:
    path = Path(directory) / 'test.db';connection = sqlite3.connect(path)
    for version in (1,2,3):
        for statement in statements(version): connection.execute(statement)
    connection.execute("INSERT INTO places (id,name,normalized_name,latitude,longitude,coordinate_system,created_at,updated_at) VALUES ('p','旧地点','旧地点',0,0,'WGS84',0,0)")
    connection.execute("INSERT INTO visits (id,place_id,visited_at,local_date,utc_offset_minutes,diary,source,created_at,updated_at) VALUES ('v','p',0,'1970-01-01',0,'旧记忆','map_selection',0,0)")
    def write(identity='a',start=540,end=600,place=None,day='2026-10-22',title='阅读',note='旧备注'):
        connection.execute(upsert,(identity,day,title,'study',start,end,place,note,100,200))
    write(place='p')
    for statement in statements(4): connection.execute(statement)
    def preserved():
        assert connection.execute('SELECT diary FROM visits').fetchone()[0]=='旧记忆'
        assert connection.execute('SELECT id,title,note,created_at FROM activities').fetchone()==('a','阅读','旧备注',100)
        assert connection.execute('SELECT count(*) FROM day_routines').fetchone()[0]==0
    check('v3 to v4 preserves IDs, notes, places and visits without inventing routines',preserved)
    def identity():
        write(place='p',title='阅读笔记')
        assert connection.execute('SELECT count(*),title,created_at FROM activities').fetchone()==(1,'阅读笔记',100)
    check('upsert retains stable identity and creation time',identity)
    def free_notes():
        write('b',570,630);write('point',700,700);write('night',1410,1620)
        assert connection.execute('SELECT count(*) FROM activities').fetchone()[0]==4
    check('overlapping notes, point entries and overnight ranges can coexist',free_notes)
    def boundaries():
        for start,end in [(-1,60),(0,2881),(61,60),(2880,2880)]:
            try: write('invalid',start,end,day='2026-10-23')
            except sqlite3.IntegrityError: pass
            else: raise AssertionError('invalid range accepted')
    check('SQL still rejects invalid time ranges',boundaries)
    def parent():
        try: write('orphan',660,720,'missing')
        except sqlite3.IntegrityError: pass
        else: raise AssertionError('orphan accepted')
        try: connection.execute("UPDATE places SET id='changed' WHERE id='p'")
        except sqlite3.IntegrityError: pass
        else: raise AssertionError('place identity change accepted')
        connection.execute("DELETE FROM places WHERE id='p'")
        assert connection.execute("SELECT place_id FROM activities WHERE id='a'").fetchone()[0] is None
        assert connection.execute('SELECT count(*) FROM visits').fetchone()[0]==0
    check('place guards survive rebuilding activity table',parent)
    def routine():
        connection.execute("INSERT INTO day_routines VALUES ('2026-10-22',445,1620,200)")
        assert connection.execute('SELECT wake_minute,sleep_minute FROM day_routines').fetchone()==(445,1620)
        try: connection.execute("UPDATE day_routines SET sleep_minute=300")
        except sqlite3.IntegrityError: pass
        else: raise AssertionError('inverted routine accepted')
    check('routine supports next-day sleep and rejects reversed boundaries',routine)
    connection.commit();connection.close();connection=sqlite3.connect(path)
    def restored():
        assert connection.execute('SELECT count(*) FROM activities').fetchone()[0]==4
        assert connection.execute('SELECT sleep_minute FROM day_routines').fetchone()[0]==1620
    check('close and reopen retains notes and routine',restored)
    connection.close()
print(f'{passed} schema checks passed; host SQLite does not replace ArkData tests.')
