// Host check for platform-free domain rules only. Device Hypium remains required.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
let deveco = process.env.DEVECO_HOME || path.join(os.homedir(), 'Applications/DevEco-Studio.app/Contents');
if (fs.existsSync(path.join(deveco, 'Contents'))) deveco = path.join(deveco, 'Contents');
const ts = require(path.join(deveco, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'loci-rules-'));
try {
  for (const relative of ['model/Atlas', 'service/VisitRules']) {
    const source = path.join(root, 'entry/src/main/ets/domain', relative + '.ets');
    const destination = path.join(temporary, relative + '.js');
    const result = ts.transpileModule(fs.readFileSync(source, 'utf8'), {
      fileName: relative + '.ts', compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 },
      reportDiagnostics: true
    });
    assert.equal((result.diagnostics || []).filter(item => item.category === ts.DiagnosticCategory.Error).length, 0);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, result.outputText);
  }
  const { VisitDraft, CoordinateSystem } = require(path.join(temporary, 'model/Atlas.js'));
  const { validateCoordinate, validateVisit, validateMemory, visitLocalDate, distanceMeters } = require(path.join(temporary, 'service/VisitRules.js'));
  let passed = 0;
  const check = (name, callback) => { callback(); passed++; process.stdout.write(`PASS ${name}\n`); };
  check('date crosses year at recorded UTC offset', () => {
    const instant = Date.parse('2025-12-31T23:30:00Z');
    assert.equal(visitLocalDate(instant, 60), '2026-01-01');
    assert.equal(visitLocalDate(instant, -480), '2025-12-31');
  });
  check('leap day and negative offset keep local visit date', () => {
    assert.equal(visitLocalDate(Date.parse('2024-03-01T01:00:00Z'), -180), '2024-02-29');
  });
  check('different coordinate systems are never nearby candidates', () => {
    const a = new VisitDraft(); const b = new VisitDraft(); b.coordinateSystem = CoordinateSystem.GCJ02;
    assert.equal(distanceMeters(a, b), Infinity);
  });
  check('same coordinate distance and adjacent place scale', () => {
    const a = new VisitDraft(); const b = new VisitDraft();
    assert.equal(distanceMeters(a, b), 0); b.latitude = 0.001;
    assert.ok(distanceMeters(a, b) > 110 && distanceMeters(a, b) < 112);
  });
  check('invalid coordinate is rejected', () => {
    const a = new VisitDraft(); a.longitude = NaN;
    assert.throws(() => validateCoordinate(a)); a.longitude = 181;
    assert.throws(() => validateCoordinate(a));
  });
  check('mood range and diary size are bounded', () => {
    assert.throws(() => validateMemory('', 6)); assert.throws(() => validateMemory('', 2.5));
    assert.throws(() => validateMemory('x'.repeat(100001), 0));
    assert.doesNotThrow(() => validateMemory('', 0));
  });
  check('new place needs a name, explicit revisit keeps identity', () => {
    const a = new VisitDraft(); a.requestId = 'visit'; a.newPlaceId = 'place';
    assert.throws(() => validateVisit(a)); a.existingPlaceId = 'existing';
    assert.doesNotThrow(() => validateVisit(a));
  });
  check('future instant and invalid local UTC offset are rejected', () => {
    const a = new VisitDraft(); a.requestId = 'visit'; a.newPlaceId = 'place'; a.name = '地点';
    a.visitedAt = Date.now() + 120000; assert.throws(() => validateVisit(a));
    a.visitedAt = Date.now(); a.utcOffsetMinutes = Infinity; assert.throws(() => validateVisit(a));
    a.utcOffsetMinutes = 900; assert.throws(() => validateVisit(a));
    a.utcOffsetMinutes = 480; assert.doesNotThrow(() => validateVisit(a));
  });
  process.stdout.write(`${passed} domain rule checks passed; platform and database behavior are not covered.\n`);
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
