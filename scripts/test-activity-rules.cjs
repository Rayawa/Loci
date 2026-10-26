// Runs the actual platform-free ArkTS source, not a duplicated implementation.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
let deveco = process.env.DEVECO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app/Contents');
if (fs.existsSync(path.join(deveco, 'Contents'))) deveco = path.join(deveco, 'Contents');
const ts = require(path.join(deveco, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'loci-activity-rules-'));
try {
  for (const relative of ['model/Activity', 'model/DayRoutine', 'service/ActivityRules']) {
    const source = path.join(root, 'entry/src/main/ets/domain', relative + '.ets');
    const result = ts.transpileModule(fs.readFileSync(source, 'utf8'), {
      fileName: relative + '.ts', compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 }, reportDiagnostics: true
    });
    assert.equal((result.diagnostics || []).filter(item => item.category === ts.DiagnosticCategory.Error).length, 0);
    const destination = path.join(temporary, relative + '.js');
    fs.mkdirSync(path.dirname(destination), { recursive: true }); fs.writeFileSync(destination, result.outputText);
  }
  const { Activity } = require(path.join(temporary, 'model/Activity.js'));
  const rules = require(path.join(temporary, 'service/ActivityRules.js'));
  const record = (id, day, start, end, title = '阅读', categoryId = 'study') => Object.assign(new Activity(), {
    id, localDate: day, startMinute: start, endMinute: end, title, categoryId
  });
  let passed = 0;
  const check = (name, callback) => { callback(); passed++; process.stdout.write(`PASS ${name}\n`); };
  check('civil dates survive leap day and year transitions', () => {
    assert.equal(rules.shiftDate('2024-02-28', 1), '2024-02-29');
    assert.equal(rules.shiftDate('2024-02-29', 1), '2024-03-01');
    assert.equal(rules.shiftDate('2026-12-31', 1), '2027-01-01');
    assert.equal(rules.shiftDate('2026-01-01', -1), '2025-12-31');
    assert.equal(rules.validDateKey('2026-02-29'), false);
    assert.equal(rules.validDateKey('2026-13-01'), false);
  });
  check('week starts Monday across years and Sunday belongs to prior week', () => {
    assert.deepEqual(rules.weekDates('2027-01-01'), ['2026-12-28','2026-12-29','2026-12-30','2026-12-31','2027-01-01','2027-01-02','2027-01-03']);
    assert.equal(rules.weekDates('2026-10-25')[0], '2026-10-19');
  });
  check('calendar-day navigation does not assume every day lasts 24 hours', () => {
    const previousTZ = process.env.TZ; process.env.TZ = 'America/New_York';
    try {
      assert.equal(rules.shiftDate('2026-03-08', 1), '2026-03-09');
      assert.equal(rules.shiftDate('2026-11-01', -1), '2026-10-31');
    } finally { if (previousTZ === undefined) delete process.env.TZ; else process.env.TZ = previousTZ; }
  });
  check('record input rejects invalid dates, categories, intervals and notes', () => {
    const a = record('a','2026-10-22',540,600);
    assert.doesNotThrow(() => rules.validateActivity(a));
    for (const patch of [{title:' '},{localDate:'2026-02-30'},{categoryId:'unknown'},{startMinute:NaN},
      {endMinute:Infinity},{startMinute:540.5},{endMinute:539},{endMinute:2881},{startMinute:-1},{note:'x'.repeat(10001)}]) {
      assert.throws(() => rules.validateActivity(Object.assign(new Activity(), a, patch)));
    }
    assert.doesNotThrow(() => rules.validateActivity(record('b','2026-10-22',0,1440)));
    assert.equal(rules.clockText(1440), '24:00');
  });
  check('adjacent intervals are allowed; contained, partial and same-time intervals overlap', () => {
    const a = record('a','2026-10-22',540,600);
    assert.equal(rules.overlaps(a,record('b',a.localDate,600,660)),false);
    assert.equal(rules.overlaps(a,record('b',a.localDate,500,541)),true);
    assert.equal(rules.overlaps(a,record('b',a.localDate,550,560)),true);
    assert.equal(rules.overlaps(a,record('b',a.localDate,540,600)),true);
    assert.equal(rules.overlaps(a,record('b','2026-10-23',540,600)),false);
    assert.equal(rules.overlaps(a,a),false);
  });
  check('extraction supports Chinese times, full-width punctuation and midnight end', () => {
    assert.deepEqual({...rules.extractActivity('09:00到10:30 阅读')}, {title:'阅读',categoryId:'study',startMinute:540,endMinute:630});
    assert.equal(rules.extractActivity('今天 9点到10点半 阅读').endMinute,630);
    assert.equal(rules.extractActivity('07:00-07:15 LociQA-Early').title,'LociQA-Early');
    assert.equal(rules.extractActivity('09：00—10：00 开发').categoryId,'work');
    assert.equal(rules.extractActivity('23:00至24:00 睡觉').endMinute,1440);
    assert.equal(rules.extractActivity('9点15分到10点45分 散步').startMinute,555);
  });
  check('ambiguous and malformed extraction never silently fills a range', () => {
    for (const input of ['下午读书','09:90到10:30 阅读','25:00到26:00 工作','9点到9点 阅读','09:00到24:01 工作','9点到10点 ']) {
      assert.throws(() => rules.extractActivity(input), input);
    }
  });
  check('category totals sum exact minutes and omit empty categories', () => {
    const records = [record('a','2026-10-22',0,30), record('b','2026-10-22',30,75,'会议','work'), record('c','2026-10-23',60,80)];
    assert.deepEqual(rules.categoryTotals(records).map(t=>[t.key,t.minutes]), [['study',50],['work',45]]);
    assert.deepEqual(rules.categoryTotals([]),[]);
  });
  check('item week stats group equal titles, include zero days, exclude other titles and weeks', () => {
    const records = [record('a','2026-10-19',0,30), record('b','2026-10-19',30,75),
      record('c','2026-10-22',0,60,'会议','work'), record('d','2026-10-26',0,90)];
    const result = rules.itemWeekTotals(records,rules.weekDates('2026-10-22'),'阅读');
    assert.deepEqual(result.map(t=>t.minutes),[75,0,0,0,0,0,0]);
  });
  check('Markdown points, wake and overnight sleep need no separating spaces', () => {
    assert.equal(rules.parseJournalLine('7:25起床').kind,'wake');
    assert.equal(rules.parseJournalLine('- 3:00睡觉',445).startMinute,1620);
    assert.equal(rules.parseJournalLine('9:10 起床').startMinute,550);
    const point=rules.parseJournalLine('12:10 备忘'); assert.equal(point.startMinute,point.endMinute);
  });
  check('cross-midnight ranges retain elapsed time and explicit next-day editing', () => {
    const a=rules.parseJournalLine('23:30-3:00 鸿蒙开发',445);
    assert.equal(a.startMinute,1410); assert.equal(a.endMinute,1620);
    const b=rules.parseJournalLine('次日 1:00-2:00 阅读',445);
    assert.equal(b.startMinute,1500); assert.equal(b.endMinute,1560);
    assert.equal(rules.dayClockText(1620),'次日 03:00');
  });
  check('routine times remain unset until recorded and reject inverted boundaries', () => {
    const { DayRoutine }=require(path.join(temporary,'model/DayRoutine.js'));
    const routine=new DayRoutine(); routine.localDate='2026-10-22';
    assert.equal(routine.wakeMinute,-1); assert.equal(routine.sleepMinute,-1);
    assert.doesNotThrow(()=>rules.validateRoutine(routine));
    routine.wakeMinute=445; routine.sleepMinute=1620; assert.doesNotThrow(()=>rules.validateRoutine(routine));
    routine.sleepMinute=300; assert.throws(()=>rules.validateRoutine(routine));
  });
  process.stdout.write(`${passed} activity rule checks passed.\n`);
} finally { fs.rmSync(temporary,{recursive:true,force:true}); }
