--------------------------------------------------------------
-- ПРОЦЕССЫ (схема processes)
-- Таблицы, представления, отчёты и др. сущности
--------------------------------------------------------------

SET search_path TO warehouse, dicts, orders, processes;

-- Таблица "История смены статусов" (партицированая по типу объектов)
CREATE TABLE IF NOT EXISTS processes.statuses_history
(
    id bigserial NOT NULL,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmend timestamptz CHECK (dttmend IS NULL or dttmend >= dttmcr),
    object_type int NOT NULL REFERENCES object_types(id),
    object_id int NOT NULL, -- не ссылается, это id сущности по типу object_type
    status_id int NOT NULL REFERENCES statuses(id),
    PRIMARY KEY (id, object_type)
) PARTITION BY LIST (object_type);

ALTER TABLE statuses_history OWNER to justcoffee;

-- Партиция по типу объекта 1
CREATE TABLE statuses_history_t1 PARTITION OF statuses_history
    FOR VALUES IN (1);

-- Партиция по типу объекта 2
CREATE TABLE statuses_history_t2 PARTITION OF statuses_history
    FOR VALUES IN (2);

-- Партиция по типу объекта 3
CREATE TABLE statuses_history_t3 PARTITION OF statuses_history
    FOR VALUES IN (3);

ALTER TABLE statuses_history_t1 OWNER to justcoffee;
ALTER TABLE statuses_history_t2 OWNER to justcoffee;
ALTER TABLE statuses_history_t3 OWNER to justcoffee;

COMMENT ON TABLE statuses_history IS 'История смены статусов';
COMMENT ON TABLE statuses_history IS 'История смены статусов для типа 1';
COMMENT ON TABLE statuses_history IS 'История смены статусов для типа 2';
COMMENT ON TABLE statuses_history IS 'История смены статусов для типа 3';

-- Индексы
CREATE INDEX object_status_type_idx ON statuses_history (object_id, status_id, object_type);
