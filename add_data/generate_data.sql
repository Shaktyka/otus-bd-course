-- Сгенерировать текстовую строку определённой длины
CREATE OR REPLACE FUNCTION warehouse.get_random_text(
	_num1 integer,
	_num2 integer,
	_set integer DEFAULT 1)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	_text text;
begin
    -- 'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЭЮЯ'
    
    with symbols(chars) as (
        VALUES ('abcdefghijklmnopqrstuvwxyz')
    )
    select 
        string_agg(substring(chars, (random() * length(chars) + 1)::int, 1), '') into _text -- выходная строка
    from symbols
    join generate_series(_num1, _num2) as word(chr_idx) on 1 = 1; -- длина слова
    
    return _text;

end;
$BODY$;

-- Сгенерировать случайное число
CREATE OR REPLACE FUNCTION warehouse.get_random_num(
	_num1 integer,
	_num2 integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	_num int;
    _arr int[];
begin
    
    select array_agg(ser.s_num) into _arr
    from generate_series(_num1, _num2) as ser(s_num);
    
    select num.id into _num
    from unnest(_arr) as num(id)
    order by random()
    limit 1;
    
    return _num;

end;
$BODY$;

-- Сгенерировать дату между указанными датами
CREATE OR REPLACE FUNCTION warehouse.get_random_date(
	_dt1 date,
	_dt2 date)
    RETURNS date
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	_date text;
    _arr date[];
    _arr_length int;
    _num int;
begin
    
    select array_agg(a.dt) into _arr
    from (
        select (generate_series( _dt1::timestamp, _dt2::timestamp, '1 day' ))::date as dt
    ) as a;
    
    _arr_length = array_length(_arr, 1);
    
    _num = warehouse.get_random_num(1, _arr_length);
    
    _date = _arr[_num];
    
    return _date;

end;
$BODY$;

-- Сгенерировать массив int
CREATE OR REPLACE FUNCTION warehouse.get_random_int_arr(
	_num1 integer default 1::int,
	_num2 integer default 100::int)
    RETURNS int[]
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    _arr int[];
    _limit int;
begin
    
    _limit = warehouse.get_random_num(1, 10);
    
    select array_agg(a.s_num) into _arr
    from (
        select * from generate_series(_num1, _num2, (random()*10)::int + 1) as ser(s_num)
        order by random()
        limit _limit
    ) as a;
    
    return _arr;

end;
$BODY$;