export class Routes {
  static readonly Place: string = 'Place';
  static readonly Memory: string = 'Memory';
  static readonly Settings: string = 'Settings';
}

export class EntityRoute {
  id: string;
  constructor(id: string) { this.id = id; }
}
