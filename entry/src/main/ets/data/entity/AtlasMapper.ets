import { relationalStore } from '@kit.ArkData';
import { CoordinateSystem, Place, Visit, VisitSource } from '../../domain/model/Atlas';

function text(row: relationalStore.ResultSet, column: string): string {
  return row.getString(row.getColumnIndex(column));
}

function number(row: relationalStore.ResultSet, column: string): number {
  return row.getDouble(row.getColumnIndex(column));
}

export function mapPlace(row: relationalStore.ResultSet): Place {
  const value = new Place();
  value.id = text(row, 'id');
  value.name = text(row, 'name');
  value.latitude = number(row, 'latitude');
  value.longitude = number(row, 'longitude');
  value.coordinateSystem = text(row, 'coordinate_system') as CoordinateSystem;
  value.address = text(row, 'address');
  value.country = text(row, 'country');
  value.countryCode = text(row, 'country_code');
  value.province = text(row, 'province');
  value.city = text(row, 'city');
  value.district = text(row, 'district');
  value.createdAt = number(row, 'created_at');
  value.updatedAt = number(row, 'updated_at');
  value.firstVisitedAt = number(row, 'first_visited_at');
  value.lastVisitedAt = number(row, 'last_visited_at');
  value.visitCount = number(row, 'visit_count');
  const yearsColumn = row.getColumnIndex('visited_years');
  value.visitedYears = row.isColumnNull(yearsColumn) ? [] : row.getString(yearsColumn).split(',');
  return value;
}

export function mapVisit(row: relationalStore.ResultSet): Visit {
  const value = new Visit();
  value.id = text(row, 'id');
  value.placeId = text(row, 'place_id');
  value.visitedAt = number(row, 'visited_at');
  value.localDate = text(row, 'local_date');
  value.utcOffsetMinutes = number(row, 'utc_offset_minutes');
  value.diary = text(row, 'diary');
  value.mood = number(row, 'mood');
  value.source = text(row, 'source') as VisitSource;
  value.createdAt = number(row, 'created_at');
  value.updatedAt = number(row, 'updated_at');
  return value;
}
