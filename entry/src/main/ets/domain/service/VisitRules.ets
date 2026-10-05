import { Coordinate, VisitDraft } from '../model/Atlas';

export function validateCoordinate(value: Coordinate): void {
  if (!Number.isFinite(value.latitude) || !Number.isFinite(value.longitude) ||
    value.latitude < -90 || value.latitude > 90 || value.longitude < -180 || value.longitude > 180) {
    throw new Error('请选择有效的地点坐标');
  }
}

export function validateMemory(diary: string, mood: number): void {
  if (diary.length > 100000) {
    throw new Error('日记最多支持 100000 个字符');
  }
  if (!Number.isInteger(mood) || mood < 0 || mood > 5) {
    throw new Error('请选择有效的心情');
  }
}

export function validateVisit(draft: VisitDraft): void {
  validateCoordinate(draft);
  validateMemory(draft.diary, draft.mood);
  if (!draft.requestId || !draft.newPlaceId) {
    throw new Error('记录标识缺失，请重新打开记录页');
  }
  if (!draft.existingPlaceId && (!draft.name.trim() || draft.name.trim().length > 120)) {
    throw new Error('地点名称须为 1–120 个字符');
  }
  if (!Number.isFinite(draft.visitedAt) || draft.visitedAt < 0 || draft.visitedAt > Date.now() + 60000) {
    throw new Error('到访时间须为现在或过去的有效时间');
  }
}

export function visitLocalDate(timestamp: number, offsetMinutes: number): string {
  const date = new Date(timestamp + offsetMinutes * 60000);
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}-${String(date.getUTCDate()).padStart(2, '0')}`;
}

export function distanceMeters(a: Coordinate, b: Coordinate): number {
  if (a.coordinateSystem !== b.coordinateSystem) {
    return Number.POSITIVE_INFINITY;
  }
  const rad = Math.PI / 180;
  const halfLat = (b.latitude - a.latitude) * rad / 2;
  const halfLon = (b.longitude - a.longitude) * rad / 2;
  const h = Math.sin(halfLat) ** 2 + Math.cos(a.latitude * rad) * Math.cos(b.latitude * rad) * Math.sin(halfLon) ** 2;
  return 6371000 * 2 * Math.asin(Math.sqrt(Math.min(1, h)));
}
