#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите название, год выпуска и средний рейтинг. Добавьте rank_by_avg_rating — ранг фильма среди всех по убыванию среднего рейтинга (одинаковые рейтинги — одинаковый ранг). Оставить 10 фильмов с наибольшим рангом."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_r AS (SELECT movie_id, AVG(rating) AS avg_rating FROM ratings GROUP BY movie_id), ranked AS (SELECT movie_id, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating FROM avg_r) SELECT m.title, m.year, r.avg_rating, r.rank_by_avg_rating FROM ranked r JOIN movies m ON m.id = r.movie_id ORDER BY r.rank_by_avg_rating LIMIT 10"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов. Для каждого жанра рассчитать средний рейтинг avg_rating. Вывести genre, avg_rating и ранг жанра по убыванию среднего рейтинга (RANK())."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM split WHERE rest <> ''), movie_genres AS (SELECT DISTINCT movie_id, genre FROM split WHERE genre <> ''), genre_avg AS (SELECT mg.genre, AVG(r.rating) AS avg_rating FROM movie_genres mg JOIN ratings r ON r.movie_id = mg.movie_id GROUP BY mg.genre) SELECT genre, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS rank FROM genre_avg ORDER BY rank"
echo " "

echo "3. Посчитайте количество фильмов в каждом жанре. Вывести genre и movie_count, отсортировать по убыванию количества."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM split WHERE rest <> '') SELECT genre, COUNT(DISTINCT movie_id) AS movie_count FROM split WHERE genre <> '' GROUP BY genre ORDER BY movie_count DESC"
echo " "

echo "4. Найдите жанры, в которых чаще всего оставляют теги. Подсчитайте общее количество записей в tags для фильмов каждого жанра. Вывести genre, tag_count и долю жанра в общем числе тегов (tag_share) в процентах."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM split WHERE rest <> ''), movie_genres AS (SELECT DISTINCT movie_id, genre FROM split WHERE genre <> ''), genre_tags AS (SELECT mg.genre, COUNT(t.id) AS tag_count FROM movie_genres mg JOIN tags t ON t.movie_id = mg.movie_id GROUP BY mg.genre), total AS (SELECT COUNT(*) AS total_tags FROM tags) SELECT gt.genre, gt.tag_count, ROUND(gt.tag_count * 100.0 / t.total_tags, 2) AS tag_share FROM genre_tags gt, total t ORDER BY gt.tag_count DESC"
echo " "

echo "5. Для каждого пользователя рассчитать общее количество оценок, средний рейтинг, дату первой и последней оценки. Вывести user_id, rating_count, avg_rating, first_rating_date, last_rating_date. Отсортировать по убыванию количества оценок, первые 10 строк."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(*) AS rating_count, ROUND(AVG(rating), 2) AS avg_rating, date(MIN(timestamp), 'unixepoch') AS first_rating_date, date(MAX(timestamp), 'unixepoch') AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10"
echo " "

echo "6. Сегментируйте пользователей по типу поведения: 'Комментаторы' — тегов больше, чем оценок; 'Оценщики' — оценок больше, чем тегов; 'Активные' — и оценок, и тегов >= 10; 'Пассивные' — и оценок, и тегов < 5. Вывести user_id, число оценок, число тегов и категорию. Используйте CASE."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH r AS (SELECT user_id, COUNT(*) AS rating_count FROM ratings GROUP BY user_id), t AS (SELECT user_id, COUNT(*) AS tag_count FROM tags GROUP BY user_id), u AS (SELECT users.id AS user_id, COALESCE(r.rating_count, 0) AS rating_count, COALESCE(t.tag_count, 0) AS tag_count FROM users LEFT JOIN r ON r.user_id = users.id LEFT JOIN t ON t.user_id = users.id) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Пассивные' END AS category FROM u ORDER BY user_id LIMIT 20"
echo " "

echo "7. Для каждого пользователя вывести имя и последний фильм, который он оценил (по timestamp). Если пользователь не оценивал — он всё равно в результате (NULL в полях фильма). Результат: user_id, name, last_rated_movie_title, last_rating_timestamp."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH last_r AS (SELECT user_id, movie_id, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC) AS rn FROM ratings) SELECT u.id AS user_id, u.name, m.title AS last_rated_movie_title, lr.timestamp AS last_rating_timestamp FROM users u LEFT JOIN last_r lr ON lr.user_id = u.id AND lr.rn = 1 LEFT JOIN movies m ON m.id = lr.movie_id ORDER BY u.id LIMIT 20"
echo " "
