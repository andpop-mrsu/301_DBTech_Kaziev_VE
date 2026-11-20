PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

INSERT OR IGNORE INTO users(name, email, gender, occupation) VALUES
('Казиев Вадим',    'kaziev.ve@example.com', 'мужской', 'студент'),
('Соседов Алексей', 'sosed1@example.com',    'мужской', 'студент'),
('Соседова Ольга',  'sosed2@example.com',    'женский', 'студентка'),
('Петров Дмитрий',  'sosed3@example.com',    'мужской', 'студент'),
('Иванова Елена',   'sosed4@example.com',    'женский', 'студентка');

INSERT OR IGNORE INTO genres(name) VALUES ('детектив'), ('приключения'), ('мультфильм');

INSERT INTO movies(title, year)
SELECT 'Тестовый фильм: Детектив', 2024
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='Тестовый фильм: Детектив' AND year=2024);

INSERT INTO movies(title, year)
SELECT 'Тестовый фильм: Приключения', 2023
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='Тестовый фильм: Приключения' AND year=2023);

INSERT INTO movies(title, year)
SELECT 'Тестовый фильм: Мультфильм', 2022
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='Тестовый фильм: Мультфильм' AND year=2022);

INSERT OR IGNORE INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g
WHERE (m.title='Тестовый фильм: Детектив'    AND m.year=2024 AND g.name='детектив')
   OR (m.title='Тестовый фильм: Приключения' AND m.year=2023 AND g.name='приключения')
   OR (m.title='Тестовый фильм: Мультфильм'  AND m.year=2022 AND g.name='мультфильм');

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kaziev.ve@example.com'
  AND m.title='Тестовый фильм: Детектив' AND m.year=2024
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id);

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kaziev.ve@example.com'
  AND m.title='Тестовый фильм: Приключения' AND m.year=2023
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id);

INSERT INTO ratings(user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5, strftime('%s','now')
FROM users u, movies m
WHERE u.email='kaziev.ve@example.com'
  AND m.title='Тестовый фильм: Мультфильм' AND m.year=2022
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id);

COMMIT;
