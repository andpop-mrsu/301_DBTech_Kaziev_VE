#!/usr/bin/env python3
"""Генерация SQL-скрипта db_init.sql для БД movies_rating.db."""
import csv
import os
import re

BASE = os.path.dirname(os.path.abspath(__file__))

DROP = """
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS users;
"""

SCHEMA = """
CREATE TABLE movies (
    id      INTEGER PRIMARY KEY,
    title   TEXT NOT NULL,
    year    INTEGER,
    genres  TEXT
);
CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    rating    REAL NOT NULL,
    timestamp INTEGER NOT NULL
);
CREATE TABLE tags (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    tag       TEXT,
    timestamp INTEGER NOT NULL
);
CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    email         TEXT,
    gender        TEXT,
    register_date TEXT,
    occupation    TEXT
);
"""


def esc(value):
    """Экранирование строки для SQL."""
    return str(value).replace("'", "''")


def parse_movies(path):
    rows = []
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            mid = int(row["movieId"])
            title_full = row["title"].strip()
            m = re.search(r"\((\d{4})\)\s*$", title_full)
            if m:
                year = int(m.group(1))
                title = title_full[: m.start()].strip()
            else:
                year = None
                title = title_full
            rows.append((mid, title, year, row["genres"].strip()))
    return rows


def parse_ratings(path):
    rows = []
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append((
                int(row["userId"]),
                int(row["movieId"]),
                float(row["rating"]),
                int(row["timestamp"]),
            ))
    return rows


def parse_tags(path):
    rows = []
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append((
                int(row["userId"]),
                int(row["movieId"]),
                row["tag"],
                int(row["timestamp"]),
            ))
    return rows


def parse_users(path):
    rows = []
    with open(path, encoding="utf-8", newline="") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if not line:
                continue
            parts = line.split("|")
            if len(parts) != 6:
                continue
            uid, name, email, gender, reg_date, occupation = parts
            rows.append((int(uid), name, email, gender, reg_date, occupation))
    return rows


def main():
    out_path = os.path.join(BASE, "db_init.sql")
    with open(out_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("BEGIN TRANSACTION;\n")
        out.write(DROP)
        out.write(SCHEMA)

        out.write("INSERT INTO movies (id, title, year, genres) VALUES\n")
        movies = parse_movies(os.path.join(BASE, "movies.csv"))
        out.write(",\n".join(
            f"({mid}, '{esc(title)}', {year if year is not None else 'NULL'}, '{esc(genres)}')"
            for mid, title, year, genres in movies
        ))
        out.write(";\n")

        out.write("INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES\n")
        ratings = parse_ratings(os.path.join(BASE, "ratings.csv"))
        out.write(",\n".join(
            f"({uid}, {mid}, {rating}, {ts})" for uid, mid, rating, ts in ratings
        ))
        out.write(";\n")

        out.write("INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES\n")
        tags = parse_tags(os.path.join(BASE, "tags.csv"))
        out.write(",\n".join(
            f"({uid}, {mid}, '{esc(tag)}', {ts})" for uid, mid, tag, ts in tags
        ))
        out.write(";\n")

        out.write("INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES\n")
        users = parse_users(os.path.join(BASE, "users.txt"))
        out.write(",\n".join(
            f"({uid}, '{esc(name)}', '{esc(email)}', '{esc(gender)}', '{esc(reg_date)}', '{esc(occupation)}')"
            for uid, name, email, gender, reg_date, occupation in users
        ))
        out.write(";\n")

        out.write("COMMIT;\n")


if __name__ == "__main__":
    main()

