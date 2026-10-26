export class Routes {
  static readonly Visit: string = 'Visit';
  static readonly Routine: string = 'Routine';
  static readonly Activity: string = 'Activity';
  static readonly Account: string = 'Account';
  static readonly Sync: string = 'Sync';
  static readonly Changelog: string = 'Changelog';
  static readonly About: string = 'About';
  static readonly Place: string = 'Place';
  static readonly Memory: string = 'Memory';
  static readonly Settings: string = 'Settings';
}

export class EntityRoute {
  id: string;
  constructor(id: string) { this.id = id; }
}
