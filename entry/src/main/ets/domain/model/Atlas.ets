export enum CoordinateSystem {
  WGS84 = 'WGS84',
  GCJ02 = 'GCJ02'
}

export enum VisitSource {
  CurrentLocation = 'current_location',
  MapSelection = 'map_selection',
  ExistingPlace = 'existing_place'
}

export interface Coordinate {
  latitude: number;
  longitude: number;
  coordinateSystem: CoordinateSystem;
}

export class Place implements Coordinate {
  id: string = '';
  name: string = '';
  latitude: number = 0;
  longitude: number = 0;
  coordinateSystem: CoordinateSystem = CoordinateSystem.WGS84;
  address: string = '';
  country: string = '';
  countryCode: string = '';
  province: string = '';
  city: string = '';
  district: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
  firstVisitedAt: number = 0;
  lastVisitedAt: number = 0;
  visitCount: number = 0;
  visitedYears: string[] = [];
}

export class Visit {
  id: string = '';
  placeId: string = '';
  visitedAt: number = 0;
  localDate: string = '';
  utcOffsetMinutes: number = 0;
  diary: string = '';
  mood: number = 0;
  source: VisitSource = VisitSource.MapSelection;
  createdAt: number = 0;
  updatedAt: number = 0;
}

export class VisitDraft implements Coordinate {
  requestId: string = '';
  newPlaceId: string = '';
  existingPlaceId: string = '';
  name: string = '';
  latitude: number = 0;
  longitude: number = 0;
  coordinateSystem: CoordinateSystem = CoordinateSystem.WGS84;
  address: string = '';
  country: string = '';
  countryCode: string = '';
  province: string = '';
  city: string = '';
  district: string = '';
  visitedAt: number = Date.now();
  utcOffsetMinutes: number = -new Date().getTimezoneOffset();
  diary: string = '';
  mood: number = 0;
  source: VisitSource = VisitSource.MapSelection;
}

export class RecordedVisit {
  placeId: string;
  visitId: string;
  isNewPlace: boolean;
  constructor(placeId: string, visitId: string, isNewPlace: boolean) {
    this.placeId = placeId; this.visitId = visitId; this.isNewPlace = isNewPlace;
  }
}

export class PlaceHistory {
  place: Place;
  visits: Visit[];
  constructor(place: Place, visits: Visit[]) { this.place = place; this.visits = visits; }
}
