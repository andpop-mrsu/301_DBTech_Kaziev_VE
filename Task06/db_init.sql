PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    gender TEXT NOT NULL CHECK (gender IN ('мужской', 'женский')),
    register_date TEXT NOT NULL DEFAULT (datetime('now')),
    occupation TEXT
);

CREATE TABLE genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE movies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    year INTEGER NOT NULL CHECK (year BETWEEN 1888 AND 2100)
);

CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL CHECK (rating >= 0 AND rating <= 5),
    timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT,
    timestamp INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_year ON movies(year);

CREATE TRIGGER trg_movies_delete_restrict
BEFORE DELETE ON movies
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM ratings WHERE movie_id = OLD.id)
BEGIN
    SELECT RAISE(ABORT, 'Нельзя удалить фильм: по нему есть отзывы');
END;

CREATE TRIGGER trg_users_delete_cascade
AFTER DELETE ON users
FOR EACH ROW
BEGIN
    DELETE FROM ratings WHERE user_id = OLD.id;
    DELETE FROM tags    WHERE user_id = OLD.id;
END;

INSERT INTO genres(name) VALUES
('драма'), ('комедия'), ('фантастика'), ('боевик'),
('триллер'), ('детектив'), ('приключения'), ('мультфильм'),
('ужасы'), ('вестерн');

INSERT INTO users(name, email, gender, occupation) VALUES
('Иванов Иван',     'ivanov@example.com',  'мужской', 'инженер'),
('Петрова Анна',    'petrova@example.com', 'женский', 'врач'),
('Сидоров Пётр',    'sidorov@example.com', 'мужской', 'учитель'),
('Смирнова Мария',  'smirnova@example.com','женский', 'дизайнер'),
('Кузнецов Олег',   'kuznetsov@example.com','мужской','программист');

INSERT INTO movies(title, year) VALUES
('Начало', 2010),
('Достать ножи', 2019),
('Волк с Уолл-стрит', 2013),
('Интерстеллар', 2014),
('Джон Уик', 2014);

INSERT INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g
WHERE (m.title = 'Начало'           AND g.name = 'фантастика')
   OR (m.title = 'Достать ножи'     AND g.name = 'детектив')
   OR (m.title = 'Достать ножи'     AND g.name = 'комедия')
   OR (m.title = 'Волк с Уолл-стрит'AND g.name = 'драма')
   OR (m.title = 'Интерстеллар'     AND g.name = 'фантастика')
   OR (m.title = 'Джон Уик'         AND g.name = 'боевик');

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5, strftime('%s','now')
FROM users u, movies m
WHERE u.email = 'ivanov@example.com' AND m.title = 'Начало';

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4, strftime('%s','now')
FROM users u, movies m
WHERE u.email = 'petrova@example.com' AND m.title = 'Достать ножи';

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5, strftime('%s','now')
FROM users u, movies m
WHERE u.email = 'sidorov@example.com' AND m.title = 'Волк с Уолл-стрит';

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4, strftime('%s','now')
FROM users u, movies m
WHERE u.email = 'smirnova@example.com' AND m.title = 'Интерстеллар';

INSERT INTO tags(user_id, movie_id, tag, timestamp)
SELECT u.id, m.id, 'научная фантастика', strftime('%s','now')
FROM users u, movies m
WHERE u.email = 'ivanov@example.com' AND m.title = 'Интерстеллар';

COMMIT;
