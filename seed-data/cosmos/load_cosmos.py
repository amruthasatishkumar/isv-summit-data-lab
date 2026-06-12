"""Idempotent loader for Cosmos DB seed data.

Reads:
    seed-data/cosmos/regions.json
    seed-data/cosmos/trainRoutes.json

Env vars:
    COSMOS_ENDPOINT     https://<acct>.documents.azure.com:443/
    COSMOS_KEY          primary key
    COSMOS_DATABASE     (default: urbanpulse)

Creates the database + 2 containers if missing, then upserts every doc.
Safe to re-run.
"""
from __future__ import annotations
import json
import os
import sys
from pathlib import Path

try:
    from azure.cosmos import CosmosClient, PartitionKey, exceptions
except ImportError:
    sys.exit(
        "azure-cosmos is not installed. Run:\n"
        "  pip install azure-cosmos"
    )


def _require(name: str) -> str:
    val = os.environ.get(name)
    if not val:
        sys.exit(f"Missing env var {name}")
    return val


def main() -> None:
    endpoint = _require("COSMOS_ENDPOINT")
    key = _require("COSMOS_KEY")
    db_name = os.environ.get("COSMOS_DATABASE", "urbanpulse")

    client = CosmosClient(endpoint, credential=key)
    db = client.create_database_if_not_exists(id=db_name)
    print(f"Database: {db_name}")

    here = Path(__file__).resolve().parent

    plan = [
        ("regions",     PartitionKey(path="/regionId"), here / "regions.json"),
        ("trainRoutes", PartitionKey(path="/routeId"),  here / "trainRoutes.json"),
    ]

    for cont_name, pk, json_path in plan:
        cont = db.create_container_if_not_exists(
            id=cont_name,
            partition_key=pk,
            offer_throughput=400,
        )
        with json_path.open("r", encoding="utf-8") as f:
            docs = json.load(f)
        for doc in docs:
            try:
                cont.upsert_item(doc)
            except exceptions.CosmosHttpResponseError as e:
                print(f"  FAILED {cont_name}/{doc.get('id')}: {e.message}")
                raise
        print(f"  -> {cont_name}: upserted {len(docs)} docs")


if __name__ == "__main__":
    main()
