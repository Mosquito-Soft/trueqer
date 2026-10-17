/**
 * Geospatial privacy and proximity utilities for Trueqer.
 * [REQ-06]: Exact residence coordinates are never stored at rest or exposed publicly.
 */

/**
 * Truncates a coordinate (latitude or longitude) to 2 decimal places (~1.1 km precision).
 */
export function truncateCoordinate(coord: number): number {
  return Math.trunc(coord * 100) / 100;
}

/**
 * Calculates Great-Circle distance between two points using the Haversine formula (in meters).
 */
export function calculateHaversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Calculates distance in kilometers between two coordinates.
 */
export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const meters = calculateHaversineDistanceMeters(lat1, lon1, lat2, lon2);
  return Math.round((meters / 1000) * 10) / 10;
}
