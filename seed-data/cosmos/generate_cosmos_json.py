"""Generate seed-data/cosmos/regions.json + trainRoutes.json from shared/ids.json.

Two containers:
  - regions      (partition key /regionId)     >= 100 docs
  - trainRoutes  (partition key /routeId)      >= 100 docs

The first 5 regions and first 3 routes come from shared/ids.json so they keep
the IDs that the SQL seed and streaming simulators depend on (R-NORTH, R-LOOP,
R-WEST, R-SOUTH, R-AIRPORT and RED, BLUE, GREEN). The rest are synthetic but
deterministic - same Random seed -> same JSON every time.
"""
from __future__ import annotations
import json
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids  # noqa: E402

# Polygon side length in degrees (~5.5 km at this latitude). Synthetic.
HALF_SIDE = 0.025

# Bulk targets for the lab (Mirroring + Direct Lake show meaningful row counts).
TARGET_REGIONS = 100
TARGET_ROUTES  = 100

# Metropolis-area lat/lon bounds for synthetic regions / stations.
LAT_MIN, LAT_MAX = 41.70, 42.05
LON_MIN, LON_MAX = -87.95, -87.50

DISTRICT_SUFFIXES = [
    "District", "Heights", "Park", "Junction", "Quarter", "Crossing",
    "Yards", "Square", "Commons", "Hills", "Plaza", "Riverside",
    "Lakeside", "Bluffs", "Gardens",
]
DISTRICT_PREFIXES = [
    "Maple", "Cedar", "Oak", "Pine", "Birch", "Elm", "Willow", "Aspen",
    "Hawthorn", "Sycamore", "Cypress", "Sequoia", "Magnolia", "Juniper",
    "Walnut", "Chestnut", "Poplar", "Spruce", "Cottonwood", "Beech",
]

ROUTE_COLORS = [
    "Amber", "Teal", "Violet", "Crimson", "Indigo", "Coral", "Slate",
    "Olive", "Maroon", "Aqua", "Bronze", "Copper", "Emerald", "Magenta",
    "Cobalt", "Saffron", "Lavender", "Rose", "Mint", "Onyx",
]


def square_polygon(lat: float, lon: float) -> list[list[float]]:
    """Return a 4-vertex closed square centered at (lat, lon) as [lon, lat] pairs."""
    return [
        [lon - HALF_SIDE, lat - HALF_SIDE],
        [lon + HALF_SIDE, lat - HALF_SIDE],
        [lon + HALF_SIDE, lat + HALF_SIDE],
        [lon - HALF_SIDE, lat + HALF_SIDE],
        [lon - HALF_SIDE, lat - HALF_SIDE],
    ]


def main() -> None:
    rng = random.Random(42)  # deterministic
    ids = load_ids()
    here = Path(__file__).resolve().parent

    # ---- regions ----
    region_docs: list[dict] = []

    # Real (UrbanPulse) regions first - keep IDs the simulators rely on.
    for r in ids["regions"]:
        hospitals_in = [h["hospitalId"] for h in ids["hospitals"] if h["regionId"] == r["regionId"]]
        stations_in = []
        for route in ids["trainRoutes"]:
            for stop in route["stops"]:
                if stop["regionId"] == r["regionId"]:
                    stations_in.append(stop["stationId"])
        region_docs.append({
            "id": r["regionId"],
            "regionId": r["regionId"],
            "name": r["name"],
            "centerLat": r["centerLat"],
            "centerLon": r["centerLon"],
            "population": r["population"],
            "hospitalIds": hospitals_in,
            "stationIds": sorted(set(stations_in)),
            "boundary": {
                "type": "Polygon",
                "coordinates": [square_polygon(r["centerLat"], r["centerLon"])],
            },
        })

    # Synthetic regions to reach TARGET_REGIONS.
    next_idx = len(region_docs) + 1
    while len(region_docs) < TARGET_REGIONS:
        region_id = f"R-{next_idx:03d}"
        next_idx += 1
        lat = round(rng.uniform(LAT_MIN, LAT_MAX), 4)
        lon = round(rng.uniform(LON_MIN, LON_MAX), 4)
        name = f"{rng.choice(DISTRICT_PREFIXES)} {rng.choice(DISTRICT_SUFFIXES)}"
        region_docs.append({
            "id": region_id,
            "regionId": region_id,
            "name": name,
            "centerLat": lat,
            "centerLon": lon,
            "population": rng.randint(8_000, 180_000),
            "hospitalIds": [],
            "stationIds": [],
            "boundary": {
                "type": "Polygon",
                "coordinates": [square_polygon(lat, lon)],
            },
        })

    (here / "regions.json").write_text(
        json.dumps(region_docs, indent=2), encoding="utf-8"
    )
    print(f"Wrote regions.json ({len(region_docs)} docs)")

    # ---- trainRoutes ----
    route_docs: list[dict] = []

    # Real (UrbanPulse) routes first.
    for route in ids["trainRoutes"]:
        route_docs.append({
            "id": route["routeId"],
            "routeId": route["routeId"],
            "color": route["color"],
            "trainIds": route["trainIds"],
            "stopCount": len(route["stops"]),
            "stops": [
                {
                    "stationId": s["stationId"],
                    "name": s["name"],
                    "regionId": s["regionId"],
                    "lat": s["lat"],
                    "lon": s["lon"],
                    "sequence": s["sequence"],
                }
                for s in route["stops"]
            ],
            "regionsServed": sorted({s["regionId"] for s in route["stops"]}),
        })

    # Synthetic routes.
    real_region_ids = [r["regionId"] for r in ids["regions"]]
    next_route_idx = len(route_docs) + 1
    while len(route_docs) < TARGET_ROUTES:
        route_id = f"RT-{next_route_idx:03d}"
        color = ROUTE_COLORS[(next_route_idx - 4) % len(ROUTE_COLORS)]
        next_route_idx += 1
        n_trains = rng.randint(2, 4)
        train_ids = [f"Train-{color}-{i}" for i in range(1, n_trains + 1)]
        n_stops = rng.randint(3, 6)
        stops = []
        regions_served = set()
        for seq in range(1, n_stops + 1):
            station_id = f"ST-{route_id[3:]}-{seq:02d}"
            region_id = rng.choice(real_region_ids)
            regions_served.add(region_id)
            stops.append({
                "stationId": station_id,
                "name": f"{rng.choice(DISTRICT_PREFIXES)} Station {seq}",
                "regionId": region_id,
                "lat": round(rng.uniform(LAT_MIN, LAT_MAX), 4),
                "lon": round(rng.uniform(LON_MIN, LON_MAX), 4),
                "sequence": seq,
            })
        route_docs.append({
            "id": route_id,
            "routeId": route_id,
            "color": color,
            "trainIds": train_ids,
            "stopCount": len(stops),
            "stops": stops,
            "regionsServed": sorted(regions_served),
        })

    (here / "trainRoutes.json").write_text(
        json.dumps(route_docs, indent=2), encoding="utf-8"
    )
    print(f"Wrote trainRoutes.json ({len(route_docs)} docs)")


if __name__ == "__main__":
    main()
