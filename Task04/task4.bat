#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары указать имена пользователей и название фильма. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON u1.id = r1.user_id JOIN users u2 ON u2.id = r2.user_id JOIN movies m ON m.id = r1.movie_id ORDER BY u1.name, u2.name, m.title LIMIT 100"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS rating_date FROM ratings r JOIN users u ON u.id = r.user_id JOIN movies m ON m.id = r.movie_id WHERE r.timestamp = (SELECT MAX(r2.timestamp) FROM ratings r2 WHERE r2.user_id = r.user_id) ORDER BY r.timestamp DESC LIMIT 10"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' должно быть 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_r AS (SELECT movie_id, AVG(rating) AS avg_rating FROM ratings GROUP BY movie_id), extremes AS (SELECT * FROM avg_r WHERE avg_rating = (SELECT MAX(avg_rating) FROM avg_r) OR avg_rating = (SELECT MIN(avg_rating) FROM avg_r)) SELECT m.title, m.year, e.avg_rating, CASE WHEN e.avg_rating = (SELECT MAX(avg_rating) FROM avg_r) THEN 'Да' ELSE 'Нет' END AS \"Рекомендуем\" FROM extremes e JOIN movies m ON m.id = e.movie_id ORDER BY m.year, m.title"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS cnt, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON u.id = r.user_id WHERE u.gender = 'female' AND date(r.timestamp, 'unixepoch') BETWEEN '2010-01-01' AND '2012-12-31'"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_r AS (SELECT movie_id, AVG(rating) AS avg_rating FROM ratings GROUP BY movie_id), ranked AS (SELECT movie_id, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS place FROM avg_r) SELECT m.title, m.year, r.avg_rating, r.place FROM ranked r JOIN movies m ON m.id = r.movie_id ORDER BY m.year, m.title LIMIT 20"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS \"Фамилия Имя|Дата регистрации\" FROM users ORDER BY register_date DESC LIMIT 10"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Должен получиться один столбец вида 1x1=1, 1x2=2, ..., 10x10=100."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE a(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM a WHERE x < 10), b(y) AS (SELECT 1 UNION ALL SELECT y + 1 FROM b WHERE y < 10) SELECT a.x || 'x' || b.y || '=' || (a.x * b.y) AS multiplication FROM a, b ORDER BY a.x, b.y"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM split WHERE rest <> '') SELECT DISTINCT genre FROM split WHERE genre <> '' ORDER BY genre"
echo " "
