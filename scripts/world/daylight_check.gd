extends RefCounted

static func is_lit(
	space: PhysicsDirectSpaceState2D,
	point: Vector2,
	origin: Vector2,
	radius: float,
	direction := Vector2.ZERO,
	half_angle_deg := 180.0,
	obstacle_mask := 1
) -> bool:
	if origin.distance_to(point) > radius:
		return false
	if half_angle_deg < 180.0 and direction.length_squared() > 0.0:
		var to_point := point - origin
		if to_point.length_squared() > 0.0:
			var angle := rad_to_deg(to_point.normalized().angle_to(direction.normalized()))
			if absf(angle) > half_angle_deg:
				return false
	var query := PhysicsRayQueryParameters2D.create(origin, point, obstacle_mask)
	return space.intersect_ray(query).is_empty()
