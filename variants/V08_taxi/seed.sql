-- =====================================================================
--  Варіант 08: Служба таксі
--  Файл 2/2: тестові дані
--  УСІ ДАНІ СИНТЕТИЧНІ. Збіги з реальними людьми випадкові.
--  Генерація детермінована (setseed) — у всіх студентів однакові дані.
--
--      psql -U postgres -d taxi -f seed.sql
-- =====================================================================

\set ON_ERROR_STOP on
SET search_path = taxi;
SELECT setseed(0.08);

-- Довідкові масиви для генерації
CREATE TEMP TABLE _n AS SELECT
    ARRAY['Шевченко','Коваленко','Бондаренко','Ткаченко','Кравченко','Олійник','Шевчук',
          'Поліщук','Мельник','Бойко','Мороз','Лисенко','Руденко','Савченко','Петренко',
          'Марченко','Гончаренко','Павленко','Левченко','Кузьменко','Ковальчук','Литвиненко',
          'Захарченко','Романенко','Карпенко'] AS last_names,
    ARRAY['Олександр','Андрій','Дмитро','Максим','Іван','Сергій','Богдан','Тарас','Олег',
          'Юрій','Петро','Назар','Віктор','Микола','Василь','Роман'] AS male_names,
    ARRAY['Олена','Наталія','Ірина','Оксана','Марія','Анна','Тетяна','Юлія',
          'Катерина','Софія','Вікторія','Ганна','Дарина','Людмила','Світлана','Галина'] AS female_names,
    ARRAY['Хрещатик','Володимирська','Січових Стрільців','Велика Васильківська',
          'Антоновича','Саксаганського','Лесі Українки','Б. Хмельницького',
          'Ярославів Вал','Іллєнка','Межигірська','Харківське шосе'] AS streets,
    ARRAY['50','63','66','67','68','73','93','95','96','97','98','99'] AS ops,
    ARRAY['305299','322001','300465','380805','320649','351005'] AS bank_codes;

-- Популярні точки Києва з координатами
CREATE TEMP TABLE _places (k int, addr text, lat numeric, lon numeric);
INSERT INTO _places VALUES
    ( 1, 'Майдан Незалежності',                       50.450100, 30.523400),
    ( 2, 'Залізничний вокзал «Київ-Пасажирський»',    50.440400, 30.488600),
    ( 3, 'Аеропорт «Київ» (Жуляни)',                  50.401700, 30.449700),
    ( 4, 'Аеропорт «Бориспіль», термінал D',          50.345000, 30.894700),
    ( 5, 'Контрактова площа',                         50.465200, 30.515600),
    ( 6, 'Площа Льва Толстого',                       50.439100, 30.516300),
    ( 7, 'ст. м. Лівобережна',                        50.451400, 30.598300),
    ( 8, 'ст. м. Позняки',                            50.398000, 30.634000),
    ( 9, 'ст. м. Оболонь',                            50.501400, 30.498000),
    (10, 'ст. м. Святошин',                           50.457800, 30.391000),
    (11, 'ст. м. Теремки',                            50.367200, 30.454500),
    (12, 'ст. м. Академмістечко',                     50.464800, 30.355200),
    (13, 'Центральний автовокзал, Деміївська пл.',    50.404500, 30.516500),
    (14, 'ст. м. Харківська',                         50.400900, 30.652400),
    (15, 'ст. м. Лісова',                             50.464800, 30.645500),
    (16, 'КПІ, просп. Берестейський, 37',             50.448900, 30.457200),
    (17, 'Лук''янівська площа',                       50.462000, 30.482000),
    (18, 'вул. Хрещатик, 22',                         50.447500, 30.522500),
    (19, 'Дарницька площа',                           50.457000, 30.615000),
    (20, 'просп. Свободи, Виноградар',                50.510000, 30.425000),
    (21, 'вул. Закревського, Троєщина',               50.519000, 30.610000),
    (22, 'Олександрівська лікарня, вул. Шовковична',  50.443300, 30.533100);

-- Моделі авто для генерації (k — індекс)
CREATE TEMP TABLE _models (k int, make text, model text, car_class text);
INSERT INTO _models VALUES
    ( 1, 'Toyota',        'Camry',    'comfort'),
    ( 2, 'Toyota',        'Corolla',  'economy'),
    ( 3, 'Skoda',         'Octavia',  'economy'),
    ( 4, 'Skoda',         'Superb',   'comfort'),
    ( 5, 'Hyundai',       'Elantra',  'economy'),
    ( 6, 'Kia',           'K5',       'comfort'),
    ( 7, 'Volkswagen',    'Passat',   'comfort'),
    ( 8, 'Renault',       'Logan',    'economy'),
    ( 9, 'Nissan',        'Leaf',     'economy'),
    (10, 'Mercedes-Benz', 'E 220',    'business'),
    (11, 'BMW',           '520d',     'business'),
    (12, 'Volkswagen',    'Touran',   'minivan'),
    (13, 'Kia',           'Carnival', 'minivan'),
    (14, 'Hyundai',       'Sonata',   'comfort'),
    (15, 'Chevrolet',     'Bolt',     'economy');

-- Офісні працівники. db_login збігатиметься з логінами, які ви створите на етапі 2.
INSERT INTO staff (full_name, position, hired_at, db_login) VALUES
    ('Мельник Ірина Петрівна',       'dispatcher', '2019-03-01', 'u_dispatcher1'),
    ('Шевчук Андрій Олегович',       'dispatcher', '2021-06-14', 'u_dispatcher2'),
    ('Литвиненко Оксана Іванівна',   'dispatcher', '2023-01-09', NULL),
    ('Гончаренко Тарас Юрійович',    'support',    '2020-09-21', 'u_support1'),
    ('Павленко Юлія Сергіївна',      'support',    '2022-04-04', 'u_support2'),
    ('Кравченко Олег Миколайович',   'support',    '2024-02-12', NULL);

-- 40 водіїв
WITH b AS MATERIALIZED (
    SELECT g,
           random() < 0.9                                    AS male,
           date '1965-01-01' + floor(random() * 13500)::int  AS birth,
           random() AS r_st, random() AS r_loc1, random() AS r_loc2
    FROM generate_series(1, 40) AS g
)
INSERT INTO drivers (last_name, first_name, birth_date, phone, license_no, tax_id, iban,
                     rating, status, hired_at, current_lat, current_lon, location_updated_at)
SELECT n.last_names[1 + floor(random() * 25)::int],
       CASE WHEN b.male THEN n.male_names[1 + floor(random() * 16)::int]
            ELSE n.female_names[1 + floor(random() * 16)::int] END,
       b.birth,
       '+380' || n.ops[1 + floor(random() * array_length(n.ops, 1))::int]
              || lpad(floor(random() * 10000000)::text, 7, '0'),
       substr('АВЕІКМНОРСТХ', 1 + floor(random() * 12)::int, 1) ||
       substr('АВЕІКМНОРСТХ', 1 + floor(random() * 12)::int, 1) ||
       substr('АВЕІКМНОРСТХ', 1 + floor(random() * 12)::int, 1) ||
       lpad(floor(random() * 1000000)::text, 6, '0'),
       lpad((b.birth - date '1899-12-31')::text, 5, '0') || lpad(floor(random() * 100000)::text, 5, '0'),
       'UA' || lpad(floor(random() * 100)::text, 2, '0')
            || n.bank_codes[1 + floor(random() * array_length(n.bank_codes, 1))::int]
            || '00000' || lpad(floor(random() * 1e14)::bigint::text, 14, '0'),
       round((4.3 + random() * 0.7)::numeric, 2),
       CASE WHEN b.g > 5 AND b.r_st < 0.05 THEN 'blocked'
            WHEN b.g > 5 AND b.r_st < 0.12 THEN 'on_leave'
            ELSE 'active' END,
       date '2018-01-01' + floor(random() * 2500)::int,
       round((50.38 + b.r_loc1 * 0.14)::numeric, 6),
       round((30.38 + b.r_loc2 * 0.30)::numeric, 6),
       now() - random() * interval '3 hours'
FROM b, _n AS n
ORDER BY b.g;

-- Логіни водіїв, яким дозволено працювати з БД через кабінет водія
UPDATE drivers SET db_login = 'u_driver' || driver_id WHERE driver_id <= 5;

-- Автомобілі: по одному на водія + 2 резервні (без водія)
INSERT INTO vehicles (driver_id, plate_no, make, model, color, prod_year, car_class)
SELECT CASE WHEN g <= 40 THEN g END,
       (ARRAY['AA','KA','AI','KI'])[1 + floor(random() * 4)::int]
           || lpad(floor(random() * 10000)::text, 4, '0')
           || substr('ABCEHIKMOPTX', 1 + floor(random() * 12)::int, 1)
           || substr('ABCEHIKMOPTX', 1 + floor(random() * 12)::int, 1),
       m.make, m.model,
       (ARRAY['білий','чорний','сірий','сріблястий','синій','червоний'])[1 + floor(random() * 6)::int],
       2012 + floor(random() * 14)::int,
       m.car_class
FROM (SELECT g, 1 + floor(random() * 15)::int AS mk FROM generate_series(1, 42) AS g OFFSET 0) x
JOIN _models m ON m.k = x.mk
ORDER BY g;

-- 180 клієнтів
INSERT INTO customers (first_name, last_name, phone, email, home_address, home_lat, home_lon,
                       registered_at, is_blocked)
SELECT CASE WHEN x.male THEN n.male_names[1 + floor(random() * 16)::int]
            ELSE n.female_names[1 + floor(random() * 16)::int] END,
       CASE WHEN random() < 0.6 THEN n.last_names[1 + floor(random() * 25)::int] END,
       '+380' || n.ops[1 + floor(random() * array_length(n.ops, 1))::int]
              || lpad(floor(random() * 10000000)::text, 7, '0'),
       CASE WHEN random() < 0.7 THEN 'client' || x.g || '@example.com' END,
       CASE WHEN x.has_home THEN
            'м. Київ, вул. ' || n.streets[1 + floor(random() * array_length(n.streets, 1))::int]
            || ', ' || (1 + floor(random() * 120))::int END,
       CASE WHEN x.has_home THEN round((50.38 + x.r1 * 0.14)::numeric, 6) END,
       CASE WHEN x.has_home THEN round((30.38 + x.r2 * 0.30)::numeric, 6) END,
       now() - interval '130 days' - random() * interval '1000 days',
       random() < 0.02
FROM (SELECT g, random() < 0.5 AS male, random() < 0.65 AS has_home,
             random() AS r1, random() AS r2
      FROM generate_series(1, 180) AS g OFFSET 0) x, _n AS n
ORDER BY x.g;

-- 450 поїздок за останні 120 днів; останні 6 — поточні (призначені / в дорозі)
WITH x AS MATERIALIZED (
    SELECT g,
           1 + floor(random() * 180)::int AS customer_id,
           CASE WHEN g > 444 THEN (g - 445) % 5 + 1                -- поточні — у водіїв u_driver1..5
                ELSE 1 + floor(random() * 40)::int END AS driver_id,
           random() < 0.25                AS by_phone,
           1 + floor(random() * 3)::int   AS disp,
           random() AS r_status, random() AS r_p, random() AS r_d,
           1 + floor(random() * 22)::int  AS pk, 1 + floor(random() * 22)::int AS dk,
           random() AS a1, random() AS a2, random() AS a3, random() AS a4,
           floor(random() * 12)::int AS st_i, (1 + floor(random() * 120))::int AS house,
           floor(random() * 12)::int AS st_j, (1 + floor(random() * 120))::int AS house2,
           CASE WHEN g > 444 THEN now() - (451 - g) * interval '7 minutes'
                ELSE now() - interval '1 hour' - random() * interval '120 days' END AS ordered_at,
           random() AS r_wait, random() AS r_rate, random() AS r_com
    FROM generate_series(1, 450) AS g
), y AS MATERIALIZED (
    SELECT x.*,
           CASE WHEN g > 444 THEN CASE WHEN g % 2 = 0 THEN 'in_progress' ELSE 'assigned' END
                WHEN r_status < 0.86 THEN 'completed'
                WHEN r_status < 0.95 THEN 'cancelled_by_customer'
                ELSE 'cancelled_by_driver' END AS status,
           -- 55 % адрес — популярні точки, решта — довільна адреса в межах міста
           CASE WHEN r_p < 0.55 THEN p.addr
                ELSE 'м. Київ, вул. ' || n.streets[1 + st_i] || ', ' || house END     AS pickup_address,
           CASE WHEN r_p < 0.55 THEN p.lat ELSE round((50.38 + a1 * 0.14)::numeric, 6) END AS pickup_lat,
           CASE WHEN r_p < 0.55 THEN p.lon ELSE round((30.38 + a2 * 0.30)::numeric, 6) END AS pickup_lon,
           CASE WHEN r_d < 0.55 THEN d.addr
                ELSE 'м. Київ, вул. ' || n.streets[1 + st_j] || ', ' || house2 END    AS dropoff_address,
           CASE WHEN r_d < 0.55 THEN d.lat ELSE round((50.38 + a3 * 0.14)::numeric, 6) END AS dropoff_lat,
           CASE WHEN r_d < 0.55 THEN d.lon ELSE round((30.38 + a4 * 0.30)::numeric, 6) END AS dropoff_lon
    FROM x
    JOIN _places p ON p.k = x.pk
    JOIN _places d ON d.k = (CASE WHEN x.dk = x.pk THEN x.dk % 22 + 1 ELSE x.dk END)
    CROSS JOIN _n AS n
), z AS MATERIALIZED (
    SELECT y.*, v.vehicle_id, v.car_class,
           -- відстань «по дорогах» ≈ пряма × 1.3; 1° широти ≈ 111 км, 1° довготи ≈ 71 км на широті Києва
           round((sqrt(power((dropoff_lat - pickup_lat) * 111, 2)
                     + power((dropoff_lon - pickup_lon) * 71, 2)) * 1.3)::numeric, 2) AS dist
    FROM y JOIN vehicles v ON v.driver_id = y.driver_id
)
INSERT INTO trips (customer_id, driver_id, vehicle_id, dispatcher_id, order_channel, car_class,
                   status, ordered_at, started_at, finished_at,
                   pickup_address, pickup_lat, pickup_lon, dropoff_address, dropoff_lat, dropoff_lon,
                   distance_km, fare, customer_rating, customer_comment)
SELECT customer_id,
       CASE WHEN status = 'cancelled_by_customer' AND r_wait < 0.5 THEN NULL ELSE driver_id END,
       CASE WHEN status = 'cancelled_by_customer' AND r_wait < 0.5 THEN NULL ELSE vehicle_id END,
       CASE WHEN by_phone THEN disp END,
       CASE WHEN by_phone THEN 'phone' ELSE 'app' END,
       car_class, status, ordered_at,
       CASE WHEN status IN ('completed', 'in_progress')
            THEN ordered_at + interval '3 minutes' + r_wait * interval '9 minutes' END,
       CASE WHEN status = 'completed'
            THEN ordered_at + interval '3 minutes' + r_wait * interval '9 minutes'
                 + (dist / 25.0 * 60 + 4) * interval '1 minute' END,
       pickup_address, pickup_lat, pickup_lon, dropoff_address, dropoff_lat, dropoff_lon,
       CASE WHEN status = 'completed' THEN dist END,
       CASE WHEN status = 'completed' THEN
            round((60 + dist * 16) * CASE car_class WHEN 'comfort' THEN 1.3 WHEN 'business' THEN 2.0
                                                    WHEN 'minivan' THEN 1.5 ELSE 1.0 END) END,
       CASE WHEN status = 'completed' AND r_rate < 0.7
            THEN (ARRAY[5,5,5,5,5,4,4,4,3,2,1])[1 + floor(r_rate / 0.7 * 11)::int] END,
       CASE WHEN status = 'completed' AND r_com < 0.12
            THEN (ARRAY['Дякую, все чудово!','Водій їхав дуже швидко','У салоні пахло цигарками',
                        'Чекав біля під''їзду, а не біля шлагбаума','Дуже ввічливий водій',
                        'Кондиціонер не працював'])[1 + floor(r_com / 0.12 * 6)::int] END
FROM z
ORDER BY ordered_at;

-- GPS-трек: 6 точок на завершену поїздку (лінійна інтерполяція + «шум»), 3 — на поточну
INSERT INTO trip_track_points (trip_id, recorded_at, lat, lon, speed_kmh)
SELECT t.trip_id,
       t.started_at + (coalesce(t.finished_at, now()) - t.started_at) * (k / 5.0),
       round(t.pickup_lat + (t.dropoff_lat - t.pickup_lat) * (k / 5.0)
             + CASE WHEN k IN (0, 5) THEN 0 ELSE ((random() - 0.5) * 0.004)::numeric END, 6),
       round(t.pickup_lon + (t.dropoff_lon - t.pickup_lon) * (k / 5.0)
             + CASE WHEN k IN (0, 5) THEN 0 ELSE ((random() - 0.5) * 0.006)::numeric END, 6),
       CASE WHEN k IN (0, 5) THEN 0 ELSE 15 + floor(random() * 55)::int END
FROM trips t
CROSS JOIN generate_series(0, 5) AS k
WHERE t.status = 'completed' OR (t.status = 'in_progress' AND k <= 2)
ORDER BY t.trip_id, k;

-- Оплати завершених поїздок
WITH x AS MATERIALIZED (
    SELECT t.trip_id, t.fare, t.finished_at, random() AS r, random() AS r2
    FROM trips t WHERE t.status = 'completed'
)
INSERT INTO payments (trip_id, amount, method, card_last4, payment_ref, status, paid_at)
SELECT trip_id, fare,
       CASE WHEN r < 0.05 THEN 'corporate' WHEN r < 0.65 THEN 'card' ELSE 'cash' END,
       CASE WHEN r >= 0.05 AND r < 0.65 THEN lpad(floor(r2 * 10000)::text, 4, '0') END,
       CASE WHEN r < 0.65 THEN 'TX-' || upper(substr(md5(trip_id::text || r2::text), 1, 16)) END,
       CASE WHEN r >= 0.05 AND r < 0.65 AND r2 < 0.02 THEN 'failed' ELSE 'paid' END,
       finished_at + interval '5 seconds'
FROM x
ORDER BY trip_id;

-- Звернення до підтримки (≈ 60)
WITH x AS MATERIALIZED (
    SELECT t.trip_id, t.customer_id, t.finished_at, t.status,
           (ARRAY['lost_item','overcharge','overcharge','driver_behavior','route','app_issue'])
               [1 + floor(random() * 6)::int] AS cat,
           random() AS r, random() AS r2, random() AS r3
    FROM (SELECT trip_id FROM trips WHERE status = 'completed' ORDER BY random() LIMIT 60) AS pick
    JOIN trips t USING (trip_id)
)
INSERT INTO support_tickets (customer_id, trip_id, staff_id, category, description, status,
                             created_at, resolved_at)
SELECT customer_id, trip_id,
       CASE WHEN st <> 'open' THEN 4 + trip_id % 3 END,
       cat,
       CASE cat
           WHEN 'lost_item'       THEN (ARRAY['Залишив у салоні телефон, чорний чохол.',
                                              'Забула парасольку на задньому сидінні.',
                                              'Залишив рюкзак з ноутбуком у багажнику.'])[1 + floor(r2 * 3)::int]
           WHEN 'overcharge'      THEN (ARRAY['Списали більше, ніж показував застосунок перед поїздкою.',
                                              'Водій поїхав довшим маршрутом, вартість зросла вдвічі.',
                                              'Двічі списали оплату за одну поїздку.'])[1 + floor(r2 * 3)::int]
           WHEN 'driver_behavior' THEN (ARRAY['Водій говорив по телефону під час руху.',
                                              'Водій відмовився вмикати кондиціонер і грубив.',
                                              'Водій курив у салоні.'])[1 + floor(r2 * 3)::int]
           WHEN 'route'           THEN (ARRAY['Водій висадив не за тією адресою.',
                                              'Поїздка тривала значно довше за прогноз.'])[1 + floor(r2 * 2)::int]
           ELSE                        (ARRAY['Застосунок не показував машину на карті.',
                                              'Не вдалося прив''язати картку.'])[1 + floor(r2 * 2)::int]
       END,
       st,
       finished_at + interval '30 minutes' + r * interval '20 hours',
       CASE WHEN st IN ('resolved', 'rejected')
            THEN finished_at + interval '1 day' + r * interval '20 hours' + r2 * interval '3 days' END
FROM (
    SELECT x.*,
           CASE WHEN finished_at > now() - interval '7 days'
                     THEN CASE WHEN r2 < 0.5 THEN 'open' ELSE 'in_progress' END
                WHEN r3 < 0.8 THEN 'resolved'
                ELSE 'rejected' END AS st
    FROM x
    OFFSET 0
) q
ORDER BY finished_at;

-- Повернення коштів за обґрунтованими скаргами на завищену вартість
UPDATE payments p SET status = 'refunded'
FROM support_tickets s
WHERE s.trip_id = p.trip_id AND s.category = 'overcharge' AND s.status = 'resolved'
  AND p.method = 'card' AND p.status = 'paid';

DROP TABLE _n;
DROP TABLE _places;
DROP TABLE _models;

-- Контроль
SELECT 'staff' AS t, count(*) FROM staff UNION ALL
SELECT 'drivers',           count(*) FROM drivers           UNION ALL
SELECT 'vehicles',          count(*) FROM vehicles          UNION ALL
SELECT 'customers',         count(*) FROM customers         UNION ALL
SELECT 'trips',             count(*) FROM trips             UNION ALL
SELECT 'trip_track_points', count(*) FROM trip_track_points UNION ALL
SELECT 'payments',          count(*) FROM payments          UNION ALL
SELECT 'support_tickets',   count(*) FROM support_tickets;
