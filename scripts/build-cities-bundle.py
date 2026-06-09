#!/usr/bin/env python3
"""
Build the bundled cities database for FocusTrain.

Downloads cities5000 from GeoNames (CC-BY 4.0), filters to the columns we need,
and writes a prebuilt SQLite database with an R-tree spatial index to
FocusTrain/Resources/cities.sqlite. The app opens it read-only and queries by
radius on demand (see CityDatabase) — nothing is loaded into RAM at launch.

Usage (run from the repo root):

    # Full refresh — download cities5000 from GeoNames and rebuild the .sqlite:
    python3 scripts/build-cities-bundle.py

    # Offline rebuild from an existing cities5000.tsv.gz (no network):
    python3 scripts/build-cities-bundle.py --from-tsv FocusTrain/Resources/cities5000.tsv.gz

The R-tree (`city_rtree`) stores each city as a degenerate point box
(min == max) in float32 — precise enough for the coarse bounding-box filter.
The exact distance is refined in Swift against the REAL lat/lon in `city`.

Network is required for the full refresh; this is run once per dataset refresh,
not in CI. The resulting cities.sqlite is committed to git.
"""

from __future__ import annotations

import gzip
import io
import pathlib
import sqlite3
import sys
import zipfile

CITIES_URL = "https://download.geonames.org/export/dump/cities5000.zip"
REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SQLITE_OUT_PATH = REPO_ROOT / "FocusTrain" / "Resources" / "cities.sqlite"

# (geonameId, name, asciiName, countryCode, lat, lon, population)
CityRow = "tuple[int, str, str, str, float, float, int]"

SCHEMA = """
CREATE TABLE city (
  geonameId   INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  asciiName   TEXT NOT NULL,
  countryCode TEXT NOT NULL,
  lat         REAL NOT NULL,
  lon         REAL NOT NULL,
  population  INTEGER NOT NULL
);
"""


def fetch(url: str) -> bytes:
    import urllib.request

    print(f"[fetch] {url}", file=sys.stderr)
    with urllib.request.urlopen(url, timeout=60) as resp:
        return resp.read()


def filter_cities(zip_bytes: bytes) -> list:
    """Read cities5000.txt from inside the zip and project to our columns."""
    rows = []
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        with zf.open("cities5000.txt") as fp:
            for raw in io.TextIOWrapper(fp, encoding="utf-8"):
                cols = raw.rstrip("\n").split("\t")
                # GeoNames cities columns (0-indexed):
                # 0 geonameid, 1 name, 2 asciiname, 3 alternatenames,
                # 4 latitude, 5 longitude, 6 fclass, 7 fcode, 8 country,
                # ... 14 population, ...
                if len(cols) < 15:
                    continue
                try:
                    geoname_id = int(cols[0])
                    name = cols[1]
                    ascii_name = cols[2]
                    lat = float(cols[4])
                    lon = float(cols[5])
                    country = cols[8]
                    population = int(cols[14]) if cols[14] else 0
                except ValueError:
                    continue
                if not name or not country:
                    continue
                rows.append((geoname_id, name, ascii_name, country, lat, lon, population))
    return rows


def read_tsv_gz(path: pathlib.Path) -> list:
    """Rebuild rows from a previously written cities5000.tsv.gz (offline path).

    Columns: geonameId, name, asciiName, countryCode, lat, lon, population.
    """
    rows = []
    with gzip.open(path, "rt", encoding="utf-8") as fp:
        for line in fp:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 7:
                continue
            try:
                geoname_id = int(cols[0])
                name = cols[1]
                ascii_name = cols[2]
                country = cols[3]
                lat = float(cols[4])
                lon = float(cols[5])
                population = int(cols[6])
            except ValueError:
                continue
            if not name or not country:
                continue
            rows.append((geoname_id, name, ascii_name, country, lat, lon, population))
    return rows


def write_sqlite(rows: list) -> None:
    SQLITE_OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    if SQLITE_OUT_PATH.exists():
        SQLITE_OUT_PATH.unlink()

    con = sqlite3.connect(str(SQLITE_OUT_PATH))
    try:
        cur = con.cursor()
        cur.executescript(SCHEMA)
        cur.executemany(
            "INSERT OR IGNORE INTO city "
            "(geonameId, name, asciiName, countryCode, lat, lon, population) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            rows,
        )
        # Spatial index: degenerate point boxes (min == max) for the coarse filter.
        cur.execute(
            "CREATE VIRTUAL TABLE city_rtree "
            "USING rtree(id, minLat, maxLat, minLon, maxLon)"
        )
        cur.execute(
            "INSERT INTO city_rtree(id, minLat, maxLat, minLon, maxLon) "
            "SELECT geonameId, lat, lat, lon, lon FROM city"
        )
        # Prefix search on asciiName ("são%") uses this index, COLLATE NOCASE.
        cur.execute(
            "CREATE INDEX idx_city_asciiname ON city(asciiName COLLATE NOCASE)"
        )
        con.commit()
        cur.execute("ANALYZE")
        con.commit()
        cur.execute("VACUUM")
        con.commit()

        count = cur.execute("SELECT count(*) FROM city").fetchone()[0]
        rtree_count = cur.execute("SELECT count(*) FROM city_rtree").fetchone()[0]
    finally:
        con.close()

    size_mb = SQLITE_OUT_PATH.stat().st_size / (1024 * 1024)
    print(
        f"[sqlite] {SQLITE_OUT_PATH.relative_to(REPO_ROOT)} — "
        f"{count} cities ({rtree_count} in r-tree), {size_mb:.2f} MB",
        file=sys.stderr,
    )
    if count != rtree_count:
        print(
            f"[warn] city/r-tree row count mismatch ({count} vs {rtree_count})",
            file=sys.stderr,
        )


def main(argv: list) -> int:
    if "--from-tsv" in argv:
        idx = argv.index("--from-tsv")
        tsv_path = (
            pathlib.Path(argv[idx + 1])
            if idx + 1 < len(argv)
            else REPO_ROOT / "FocusTrain" / "Resources" / "cities5000.tsv.gz"
        )
        if not tsv_path.exists():
            print(f"[error] tsv not found: {tsv_path}", file=sys.stderr)
            return 1
        print(f"[read] {tsv_path}", file=sys.stderr)
        rows = read_tsv_gz(tsv_path)
    else:
        rows = filter_cities(fetch(CITIES_URL))

    if not rows:
        print("[error] no city rows produced", file=sys.stderr)
        return 1

    # Population descending: keeps the heaviest cities first, so search ties and
    # the ladder bucket ("most plausible city near distance X") favour big names.
    rows.sort(key=lambda r: r[6], reverse=True)
    write_sqlite(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
