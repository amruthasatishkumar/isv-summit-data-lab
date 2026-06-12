"""Stream synthetic train telemetry to Event Hub `metrotrain`.

Schema (must match M3 KQL `TrainTelemetry` table exactly):
    trainId, line, lat, lon, speed, status, timestamp

Each train walks its assigned route's stops in order, with realistic dwell time
at each stop and constant-velocity interpolation between stops.

Env vars:
    EVENTHUB_TRAIN_CONN_STR  (full connection string with EntityPath=metrotrain)
    SIM_DURATION_SECONDS     (optional, default 600)
    SIM_INTERVAL_SECONDS     (optional, default 2.0)
"""
from __future__ import annotations
import json
import os
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    from azure.eventhub import EventHubProducerClient, EventData
except ImportError:
    sys.exit("azure-eventhub not installed. Run: pip install azure-eventhub")

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids  # noqa: E402

# Fraction of segment a train advances per tick when in motion (~ 60 ticks per stop)
PROGRESS_PER_TICK = 1.0 / 60.0
DWELL_TICKS = 5
SPEED_MPH_RANGE = (22.0, 38.0)


class Train:
    def __init__(self, train_id: str, line: str, stops: list[dict]):
        self.train_id = train_id
        self.line = line
        self.stops = stops
        # Stagger initial positions so trains don't all teleport together
        self.idx = random.randint(0, len(stops) - 1)
        self.progress = 0.0
        self.dwell = random.randint(0, DWELL_TICKS)
        self.direction = 1  # 1 = forward, -1 = reverse
        self.target_speed = random.uniform(*SPEED_MPH_RANGE)

    def tick(self) -> dict:
        s_from = self.stops[self.idx]
        next_idx = self.idx + self.direction
        if next_idx < 0 or next_idx >= len(self.stops):
            # Reverse at end of line
            self.direction *= -1
            next_idx = self.idx + self.direction
        s_to = self.stops[next_idx]

        if self.dwell > 0:
            # Sitting at station
            self.dwell -= 1
            lat, lon, speed = s_from["lat"], s_from["lon"], 0.0
            status = "stopped"
        else:
            self.progress += PROGRESS_PER_TICK
            if self.progress >= 1.0:
                # Arrived at next stop, start dwell
                self.idx = next_idx
                self.progress = 0.0
                self.dwell = DWELL_TICKS
                lat, lon, speed = s_to["lat"], s_to["lon"], 0.0
                status = "stopped"
            else:
                lat = s_from["lat"] + (s_to["lat"] - s_from["lat"]) * self.progress
                lon = s_from["lon"] + (s_to["lon"] - s_from["lon"]) * self.progress
                speed = self.target_speed + random.uniform(-2.0, 2.0)
                status = "in-transit"

        # Random fault injection (~1.5% of ticks)
        if random.random() < 0.015 and status == "in-transit":
            status = "fault"
            speed = max(0.0, speed - 15.0)

        return {
            "trainId":   self.train_id,
            "line":      self.line,
            "lat":       round(lat, 6),
            "lon":       round(lon, 6),
            "speed":     round(speed, 2),
            "status":    status,
            "timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        }


def main() -> None:
    conn_str = os.environ.get("EVENTHUB_TRAIN_CONN_STR")
    if not conn_str:
        sys.exit("EVENTHUB_TRAIN_CONN_STR not set")

    duration = float(os.environ.get("SIM_DURATION_SECONDS", "600"))
    interval = float(os.environ.get("SIM_INTERVAL_SECONDS", "2.0"))

    ids = load_ids()
    trains: list[Train] = []
    for route in ids["trainRoutes"]:
        for tid in route["trainIds"]:
            trains.append(Train(tid, route["color"], route["stops"]))

    producer = EventHubProducerClient.from_connection_string(conn_str)
    print(f"Streaming metrotrain for {duration}s every {interval}s "
          f"(trains={len(trains)})")

    end = time.time() + duration
    n = 0
    try:
        while time.time() < end:
            batch = producer.create_batch()
            for tr in trains:
                evt = tr.tick()
                batch.add(EventData(json.dumps(evt)))
            producer.send_batch(batch)
            n += len(batch)
            time.sleep(interval)
    except KeyboardInterrupt:
        print("Interrupted by user.")
    finally:
        producer.close()
        print(f"Sent {n} events.")


if __name__ == "__main__":
    main()
