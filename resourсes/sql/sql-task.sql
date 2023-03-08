-- Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT aircraft_code, model:: json ->> 'ru' AS ru_aircraft, fare_conditions, count(fare_conditions) AS seats
FROM aircrafts_data
         INNER JOIN seats USING (aircraft_code)
GROUP BY aircraft_code, fare_conditions
ORDER BY aircraft_code, fare_conditions;

-- Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT aircraft_code, model:: json ->> 'ru' AS ru_aircraft, count(fare_conditions) AS seats
FROM aircrafts_data
         INNER JOIN seats USING (aircraft_code)
GROUP BY aircraft_code
ORDER BY seats DESC
LIMIT 3;

-- Вывести код,модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам
SELECT aircraft_code, model:: json ->> 'ru' AS ru_aircraft, seat_no, fare_conditions
FROM aircrafts_data
         INNER JOIN seats USING (aircraft_code)
WHERE model:: json ->> 'ru' = 'Аэробус A321-200'
  AND fare_conditions != 'Economy'
ORDER BY seat_no;

-- Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airport_code, airport_name:: json ->> 'ru' AS ru_airport, city :: json ->> 'ru' AS ru_city
FROM airports_data
WHERE city IN (SELECT city
               FROM airports_data
               GROUP BY city
               HAVING count(airport_code) > 1);

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT flight_no,
       model:: json ->> 'ru'          AS ru_aircraft,
       d.airport_name:: json ->> 'ru' AS ru_departure_airport,
       a.airport_name:: json ->> 'ru' AS ru_arrival_airport,
       scheduled_departure,
       scheduled_arrival,
       status
FROM flights
         INNER JOIN aircrafts_data USING (aircraft_code)
         INNER JOIN airports_data d ON departure_airport = d.airport_code
         INNER JOIN airports_data a ON arrival_airport = a.airport_code
WHERE departure_airport IN (SELECT airport_code
                            FROM airports_data
                            WHERE city:: json ->> 'ru' = 'Екатеринбург')
  AND arrival_airport IN (SELECT airport_code
                          FROM airports_data
                          WHERE city:: json ->> 'ru' = 'Москва')
  AND status IN ('On Time', 'Delayed')
  AND scheduled_departure > bookings.now()
ORDER BY scheduled_departure
LIMIT 1;

-- Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)
WITH tickets_cost AS (SELECT ticket_no, sum(amount) AS total
                      FROM ticket_flights
                      GROUP BY ticket_no),
     min_ticket AS (SELECT ticket_no
                    FROM tickets_cost
                    WHERE total = (SELECT min(total) FROM tickets_cost)
                    limit 1),
     max_ticket AS (SELECT ticket_no
                    FROM tickets_cost
                    WHERE total = (SELECT max(total) FROM tickets_cost)
                    limit 1)
SELECT ticket_no, total, passenger_name, contact_data
FROM tickets_cost
         INNER JOIN tickets USING (ticket_no)
WHERE ticket_no = (SELECT * FROM min_ticket)
   OR ticket_no = (SELECT * FROM max_ticket)
ORDER BY total;

-- Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints) .
CREATE TABLE IF NOT EXISTS customers
(
    id         BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(50)        NOT NULL CHECK (length(first_name) > 0),
    last_name  VARCHAR(50)        NOT NULL CHECK (length(last_name) > 0),
    email      VARCHAR(30) UNIQUE NOT NULL,
    phone      VARCHAR(20) UNIQUE NOT NULL,
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

-- Написать DDL таблицы Orders , должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + ограничения
CREATE TABLE IF NOT EXISTS orders
(
    id         BIGSERIAL PRIMARY KEY,
    customerId INTEGER NOT NULL,
    quantity   INTEGER NOT NULL CHECK ( quantity > 0 ),
    FOREIGN KEY (customerId) REFERENCES customers (id)
);

-- Написать 5 insert в эти таблицы
INSERT INTO customers(first_name, last_name, email, phone)
VALUES ('ivan', 'ivanov', 'ivanov@gov.by', '+375-25-25-25-250'),
       ('petr', 'petrov', 'petrov@gov.by', '+375-25-25-25-251'),
       ('nikolay', 'nikolaev', 'nikolaev@gov.by', '+375-25-25-25-252'),
       ('alex', 'alexandrov', 'alexandrov@gov.by', '+375-25-25-25-253'),
       ('dmitry', 'dmitrov', 'dmitrov@gov.by', '+375-25-25-25-254');

INSERT INTO orders(customerId, quantity)
VALUES (1, 10),
       (1, 20),
       (2, 15),
       (3, 1),
       (4, 100);

-- удалить таблицы
DROP TABLE IF EXISTS orders, customers;

-- Написать свой кастомный запрос (rus + sql)
-- Руководство хочет узнать ТОП-3 самолета по количеству совершенных рейсов за все время
SELECT aircraft_code, model:: json ->> 'ru' AS ru_aircraft, flights_amount, position
FROM (SELECT aircraft_code,
             count(aircraft_code)                              AS flights_amount,
             rank() OVER (ORDER BY count(aircraft_code) DESC ) AS position
      FROM flights
      WHERE status = 'Arrived'
      GROUP BY aircraft_code) as aircraft_flights
         INNER JOIN aircrafts_data USING (aircraft_code)
WHERE position <= 3
ORDER BY position;
