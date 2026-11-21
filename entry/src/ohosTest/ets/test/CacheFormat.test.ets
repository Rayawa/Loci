import { describe, expect, it } from '@ohos/hypium';
import { formatBytes } from '../../../main/ets/common/cacheFormat';

export default function cacheFormatTest(): void {
  describe('CacheFormat', () => {
    it('zeroAndUnknownSizesDoNotInventUsage', 0, () => {
      expect(formatBytes(undefined)).assertEqual('-'); expect(formatBytes(-1)).assertEqual('-');
      expect(formatBytes(Number.NaN)).assertEqual('-'); expect(formatBytes(0)).assertEqual('0 B');
    });
    it('storageUnitsSwitchAtBinaryBoundaries', 0, () => {
      expect(formatBytes(1023)).assertEqual('1023 B'); expect(formatBytes(1024)).assertEqual('1 KB');
      expect(formatBytes(1536)).assertEqual('1.5 KB'); expect(formatBytes(1048576)).assertEqual('1 MB');
      expect(formatBytes(1073741824)).assertEqual('1 GB');
    });
    it('roundedSizesStayCompactAcrossUnitTransitions', 0, () => {
      expect(formatBytes(140556)).assertEqual('137.3 KB');
      expect(formatBytes(1048575)).assertEqual('1 MB');
      expect(formatBytes(1572864)).assertEqual('1.5 MB');
    });
  });
}
