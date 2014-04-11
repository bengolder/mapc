alter table sample_points
    add column co2_avg numeric,
    add column co2_2008_1 numeric,
    add column co2_2008_2 numeric,
    add column co2_2008_3 numeric,
    add column co2_2008_4 numeric,
    add column co2_2009_1 numeric,
    add column co2_2009_2 numeric,
    add column co2_2009_3 numeric,
    add column co2_2009_4 numeric,
    add column co2_2010_1 numeric,
    add column co2_2010_2 numeric,
    add column co2_2010_3 numeric,
    add column co2_2010_4 numeric,
    add column co2_2011_1 numeric,
    add column co2_2011_2 numeric,
    add column co2_2011_3 numeric,
    add column co2_2011_4 numeric
;

-- select distinct quarter from squares
-- order by quarter;
-- 2008_q1
-- 2008_q2
-- 2008_q3
-- 2008_q4
-- 2009_q1
-- 2009_q2
-- 2009_q3
-- 2009_q4
-- 2010_q1
-- 2010_q2
-- 2010_q3
-- 2010_q4
-- 2011_q1
-- 2011_q2
-- 2011_q3
-- 2011_q4


update sample_points as p
set co2_2008_1 = d.co2eqv_day
from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2008_q1'
    ) as d
where p.id = d.g250m_id
;

update sample_points as p
    set co2_2008_2 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2008_q2'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2008_3 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2008_q3'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2008_4 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2008_q4'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2009_1 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2009_q1'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2009_2 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2009_q2'
    ) as d
    where p.id = d.g250m_id
;
update sample_points as p
    set co2_2009_3 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2009_q3'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2009_4 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2009_q4'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2010_1 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2010_q1'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2010_2 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2010_q2'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2010_3 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2010_q3'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2010_4 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2010_q4'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2011_1 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2011_q1'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2011_2 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2011_q2'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2011_3 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2011_q3'
    ) as d
    where p.id = d.g250m_id
;

update sample_points as p
    set co2_2011_4 = d.co2eqv_day
    from (
        select 
            g250m_id,
            co2eqv_day
        from squares
        where quarter = '2011_q4'
    ) as d
    where p.id = d.g250m_id
;

update sample_points
    set co2_avg = (
        co2_2008_1 + 
        co2_2008_2 + 
        co2_2008_3 + 
        co2_2008_4 + 
        co2_2009_1 + 
        co2_2009_2 + 
        co2_2009_3 + 
        co2_2009_4 + 
        co2_2010_1 + 
        co2_2010_2 + 
        co2_2010_3 + 
        co2_2010_4 + 
        co2_2011_1 + 
        co2_2011_2 + 
        co2_2011_3 + 
        co2_2011_4
    ) / 16::float
;

