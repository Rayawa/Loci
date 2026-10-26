export function categoryColor(id: string): Resource {
  if (id === 'work') { return $r('app.color.activity_work'); }
  if (id === 'study') { return $r('app.color.activity_study'); }
  if (id === 'life') { return $r('app.color.activity_life'); }
  if (id === 'exercise') { return $r('app.color.activity_exercise'); }
  if (id === 'rest') { return $r('app.color.activity_rest'); }
  if (id === 'travel') { return $r('app.color.activity_travel'); }
  return $r('app.color.activity_other');
}
