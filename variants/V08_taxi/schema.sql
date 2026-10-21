-- =====================================================================
--  Практична робота «Захист БД PostgreSQL»
--  Варіант 08: Служба таксі
--  Файл 1/2: схема (DDL)
--
--  Запуск (у вже створеній БД taxi):
--      psql -U postgres -d taxi -f schema.sql
--  Персональні / чутливі поля позначені в COMMENT ON COLUMN міткою [ПД] або [ЧУТЛИВЕ].
--  Ролі та права НЕ створюються тут — це завдання етапу 2.
--  Координати — звичайні numeric(9,6) (широта/довгота WGS-84), без PostGIS.
-- =====================================================================

\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS taxi;
COMMENT ON SCHEMA taxi IS 'Варіант 08: служба таксі — замовлення, поїздки, GPS-трек, оплати, звернення';

-- Офісні працівники (диспетчери, підтримка).
-- Поле db_login пов'язує рядок з обліковим записом PostgreSQL.
CREATE TABLE taxi.staff (
    staff_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   text NOT NULL,
    position    text NOT NULL CHECK (position IN ('dispatcher', 'support')),
    hired_at    date NOT NULL,
    db_login    name UNIQUE
);
COMMENT ON COLUMN taxi.staff.full_name IS '[ПД] ПІБ працівника';
COMMENT ON COLUMN taxi.staff.db_login  IS 'Логін PostgreSQL';

-- Водії (ФОП-партнери служби). db_login — для RLS по поїздках (current_user) на етапі 3.
CREATE TABLE taxi.drivers (
    driver_id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    last_name           text NOT NULL,
    first_name          text NOT NULL,
    birth_date          date NOT NULL,
    phone               text NOT NULL UNIQUE,
    license_no          text NOT NULL UNIQUE CHECK (license_no ~ '^[А-ЯІЇЄҐ]{3}[0-9]{6}$'),
    tax_id              text NOT NULL UNIQUE CHECK (tax_id ~ '^[0-9]{10}$'),
    iban                text NOT NULL CHECK (iban ~ '^UA[0-9]{27}$'),
    rating              numeric(3,2) CHECK (rating BETWEEN 1 AND 5),
    status              text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'blocked')),
    hired_at            date NOT NULL,
    current_lat         numeric(9,6) CHECK (current_lat BETWEEN 44 AND 53),
    current_lon         numeric(9,6) CHECK (current_lon BETWEEN 22 AND 41),
    location_updated_at timestamptz,
    db_login            name UNIQUE
);
COMMENT ON TABLE  taxi.drivers                     IS 'Водії-партнери';
COMMENT ON COLUMN taxi.drivers.last_name           IS '[ПД] Прізвище';
COMMENT ON COLUMN taxi.drivers.first_name          IS '[ПД] Ім''я (показується клієнту)';
COMMENT ON COLUMN taxi.drivers.birth_date          IS '[ПД] Дата народження';
COMMENT ON COLUMN taxi.drivers.phone               IS '[ПД] Телефон';
COMMENT ON COLUMN taxi.drivers.license_no          IS '[ПД][ЧУТЛИВЕ] Номер посвідчення водія';
COMMENT ON COLUMN taxi.drivers.tax_id              IS '[ПД][ЧУТЛИВЕ] РНОКПП (ІПН) водія-ФОП';
COMMENT ON COLUMN taxi.drivers.iban                IS '[ПД][ЧУТЛИВЕ] IBAN для виплат';
COMMENT ON COLUMN taxi.drivers.current_lat         IS '[ПД][ЧУТЛИВЕ] Поточна геолокація водія — широта';
COMMENT ON COLUMN taxi.drivers.current_lon         IS '[ПД][ЧУТЛИВЕ] Поточна геолокація водія — довгота';
COMMENT ON COLUMN taxi.drivers.db_login            IS 'Логін PostgreSQL (для RLS); NULL — водій працює лише через мобільний застосунок';

-- Автомобілі
CREATE TABLE taxi.vehicles (
    vehicle_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_id   integer UNIQUE REFERENCES taxi.drivers(driver_id),
    plate_no    text NOT NULL UNIQUE CHECK (plate_no ~ '^[ABCEHIKMOPTX]{2}[0-9]{4}[ABCEHIKMOPTX]{2}$'),
    make        text NOT NULL,
    model       text NOT NULL,
    color       text NOT NULL,
    prod_year   smallint NOT NULL CHECK (prod_year BETWEEN 2005 AND 2030),
    car_class   text NOT NULL CHECK (car_class IN ('economy', 'comfort', 'business', 'minivan'))
);
COMMENT ON COLUMN taxi.vehicles.plate_no IS '[ПД] Держномер (через реєстр МВС дає власника)';

-- Клієнти — основна таблиця з персональними даними
CREATE TABLE taxi.customers (
    customer_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    text NOT NULL,
    last_name     text,
    phone         text NOT NULL UNIQUE,
    email         text,
    home_address  text,
    home_lat      numeric(9,6) CHECK (home_lat BETWEEN 44 AND 53),
    home_lon      numeric(9,6) CHECK (home_lon BETWEEN 22 AND 41),
    registered_at timestamptz NOT NULL DEFAULT now(),
    is_blocked    boolean NOT NULL DEFAULT false,
    CHECK ((home_lat IS NULL) = (home_lon IS NULL))
);
COMMENT ON TABLE  taxi.customers              IS 'Клієнти служби';
COMMENT ON COLUMN taxi.customers.first_name   IS '[ПД] Ім''я';
COMMENT ON COLUMN taxi.customers.last_name    IS '[ПД] Прізвище';
COMMENT ON COLUMN taxi.customers.phone        IS '[ПД][ЧУТЛИВЕ] Телефон (логін у застосунку)';
COMMENT ON COLUMN taxi.customers.email        IS '[ПД] Email';
COMMENT ON COLUMN taxi.customers.home_address IS '[ПД][ЧУТЛИВЕ] Збережена адреса «Дім»';
COMMENT ON COLUMN taxi.customers.home_lat     IS '[ПД][ЧУТЛИВЕ] Координати адреси «Дім» — широта';
COMMENT ON COLUMN taxi.customers.home_lon     IS '[ПД][ЧУТЛИВЕ] Координати адреси «Дім» — довгота';

-- Поїздки (замовлення)
CREATE TABLE taxi.trips (
    trip_id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      integer NOT NULL REFERENCES taxi.customers(customer_id),
    driver_id        integer REFERENCES taxi.drivers(driver_id),
    vehicle_id       integer REFERENCES taxi.vehicles(vehicle_id),
    dispatcher_id    integer REFERENCES taxi.staff(staff_id),
    order_channel    text NOT NULL CHECK (order_channel IN ('app', 'phone')),
    car_class        text NOT NULL CHECK (car_class IN ('economy', 'comfort', 'business', 'minivan')),
    status           text NOT NULL CHECK (status IN ('searching', 'assigned', 'in_progress', 'completed',
                                                     'cancelled_by_customer', 'cancelled_by_driver')),
    ordered_at       timestamptz NOT NULL,
    started_at       timestamptz,
    finished_at      timestamptz,
    pickup_address   text NOT NULL,
    pickup_lat       numeric(9,6) NOT NULL CHECK (pickup_lat BETWEEN 44 AND 53),
    pickup_lon       numeric(9,6) NOT NULL CHECK (pickup_lon BETWEEN 22 AND 41),
    dropoff_address  text NOT NULL,
    dropoff_lat      numeric(9,6) NOT NULL CHECK (dropoff_lat BETWEEN 44 AND 53),
    dropoff_lon      numeric(9,6) NOT NULL CHECK (dropoff_lon BETWEEN 22 AND 41),
    distance_km      numeric(6,2) CHECK (distance_km >= 0),
    fare             numeric(8,2) CHECK (fare >= 0),
    customer_rating  smallint CHECK (customer_rating BETWEEN 1 AND 5),
    customer_comment text,
    CHECK (order_channel = 'app' OR dispatcher_id IS NOT NULL),
    CHECK (started_at IS NULL OR started_at >= ordered_at),
    CHECK (finished_at IS NULL OR finished_at > started_at),
    CHECK (status <> 'completed' OR (driver_id IS NOT NULL AND finished_at IS NOT NULL))
);
COMMENT ON COLUMN taxi.trips.customer_id      IS '[ПД] Хто їхав';
COMMENT ON COLUMN taxi.trips.driver_id        IS 'Водій (для RLS)';
COMMENT ON COLUMN taxi.trips.pickup_address   IS '[ПД][ЧУТЛИВЕ] Адреса подачі';
COMMENT ON COLUMN taxi.trips.pickup_lat       IS '[ПД][ЧУТЛИВЕ] Геолокація подачі — широта';
COMMENT ON COLUMN taxi.trips.pickup_lon       IS '[ПД][ЧУТЛИВЕ] Геолокація подачі — довгота';
COMMENT ON COLUMN taxi.trips.dropoff_address  IS '[ПД][ЧУТЛИВЕ] Адреса призначення';
COMMENT ON COLUMN taxi.trips.dropoff_lat      IS '[ПД][ЧУТЛИВЕ] Геолокація призначення — широта';
COMMENT ON COLUMN taxi.trips.dropoff_lon      IS '[ПД][ЧУТЛИВЕ] Геолокація призначення — довгота';
COMMENT ON COLUMN taxi.trips.customer_comment IS '[ПД] Коментар клієнта (може містити будь-що)';

-- GPS-трек поїздки (точки від застосунку водія)
CREATE TABLE taxi.trip_track_points (
    point_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id      integer NOT NULL REFERENCES taxi.trips(trip_id),
    recorded_at  timestamptz NOT NULL,
    lat          numeric(9,6) NOT NULL CHECK (lat BETWEEN 44 AND 53),
    lon          numeric(9,6) NOT NULL CHECK (lon BETWEEN 22 AND 41),
    speed_kmh    smallint CHECK (speed_kmh BETWEEN 0 AND 200)
);
COMMENT ON TABLE  taxi.trip_track_points     IS 'Історія переміщень: де і коли перебували водій і пасажир';
COMMENT ON COLUMN taxi.trip_track_points.lat IS '[ПД][ЧУТЛИВЕ] Широта';
COMMENT ON COLUMN taxi.trip_track_points.lon IS '[ПД][ЧУТЛИВЕ] Довгота';

-- Оплати поїздок
CREATE TABLE taxi.payments (
    payment_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id      integer NOT NULL UNIQUE REFERENCES taxi.trips(trip_id),
    amount       numeric(8,2) NOT NULL CHECK (amount >= 0),
    method       text NOT NULL CHECK (method IN ('cash', 'card', 'corporate')),
    card_last4   text CHECK (card_last4 ~ '^[0-9]{4}$'),
    payment_ref  text UNIQUE,
    status       text NOT NULL CHECK (status IN ('paid', 'failed', 'refunded')),
    paid_at      timestamptz NOT NULL,
    CHECK ((method = 'card') = (card_last4 IS NOT NULL)),
    CHECK (method = 'cash' OR payment_ref IS NOT NULL)
);
COMMENT ON COLUMN taxi.payments.card_last4  IS '[ЧУТЛИВЕ] Останні 4 цифри картки';
COMMENT ON COLUMN taxi.payments.payment_ref IS '[ЧУТЛИВЕ] Ідентифікатор транзакції в платіжному провайдері';

-- Звернення до служби підтримки
CREATE TABLE taxi.support_tickets (
    ticket_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  integer NOT NULL REFERENCES taxi.customers(customer_id),
    trip_id      integer REFERENCES taxi.trips(trip_id),
    staff_id     integer REFERENCES taxi.staff(staff_id),
    category     text NOT NULL CHECK (category IN ('lost_item', 'overcharge', 'driver_behavior',
                                                   'route', 'app_issue')),
    description  text NOT NULL,
    status       text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'rejected')),
    created_at   timestamptz NOT NULL,
    resolved_at  timestamptz,
    CHECK (resolved_at IS NULL OR resolved_at > created_at)
);
COMMENT ON COLUMN taxi.support_tickets.customer_id IS '[ПД] Автор звернення';
COMMENT ON COLUMN taxi.support_tickets.description IS '[ПД] Текст звернення';

CREATE INDEX ON taxi.trips (driver_id);
CREATE INDEX ON taxi.trips (customer_id);
CREATE INDEX ON taxi.trips (ordered_at);
CREATE INDEX ON taxi.trip_track_points (trip_id, recorded_at);
CREATE INDEX ON taxi.support_tickets (trip_id);
