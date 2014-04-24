-- here we assume that we have already copied in 3 datasets:
-- grid_quarters_public and rae_public
-- as well as the grid shapefile (using ogr2ogr into a table named 'grid')
-- and the grid attributes (as shown below)
copy grid_atts from
    '/home/bgolder/projects/mapc/data/Tabular/grid250m_attributes.csv'
    delimiter ','
    csv header
;

-- create averages of the 2010 quarters
drop table if exists avgs_2010;
create table avgs_2010 as (
    select
      g250m_id,
      avg(veh_lo) as veh_lo,
      avg(veh_hi) as veh_hi,
      avg(pass_veh) as pass_veh,
      avg(glpdaypass) as fuelperday,
      avg(co2eqv_day) as co2perday
    from grid_quarters_public
    where
        quarter like '2010%'
    group by g250m_id
);


-- grab centroids of each grid polygon and
-- add all desired attributes to each point
drop table if exists avgs_pts;
create table avgs_pts as (
    select
        p.g250m_id as grid_id,
        ST_Centroid(p.wkb_geometry) as pt,
        a.pop10,
        a.hh10,
        d.veh_lo,
        d.veh_hi,
        d.pass_veh,
        d.fuelperday,
        d.co2perday
    from grid as p
    join avgs_2010 as d on d.g250m_id = p.g250m_id
    join grid_atts as a on a.g250m_id = p.g250m_id
);

-- create a spatial index for smoothing lookups
drop index if exists pt_index;
create index pt_index on avgs_pts using gist ( pt );

-- register the index for future lookups
vacuum (analyze) avgs_pts;

-- smooth it out, yeah
-- using a 9-square grid average
drop table if exists smooth_operator;
create table smooth_operator as (
    select
        a.grid_id,
        a.pt,
        count(b.pt) as count,
        avg(b.pop10) as pop10,
        avg(b.hh10) as hh10,
        avg(b.veh_lo) as veh_lo,
        avg(b.veh_hi) as veh_hi,
        avg(b.pass_veh) as pass_veh,
        avg(b.fuelperday) as fuelperday,
        avg(b.co2perday) as co2perday
    from avgs_pts as a 
    join avgs_pts as b on ST_DWithin(a.pt, b.pt, 360)
    group by a.grid_id, a.pt
);

-- normalize by lots of things
drop table if exists normal_and_smooth;
create table normal_and_smooth as (
    select
        pt,
        grid_id,
        count,
        pop10,
        hh10,
        pass_veh,
        (case when pass_veh = 0 then null
            else veh_hi / pass_veh end) as rate_veh_hi,
        (case when pass_veh = 0 then null
            else veh_lo / pass_veh end) as rate_veh_lo,

        (case when pop10 = 0 then null
            else pass_veh / pop10 end) as veh_person,
        (case when pop10 = 0 then null
            else fuelperday / pop10 end) as fuel_person,
        (case when pop10 = 0 then null
            else co2perday / pop10 end) as co2_person,

        (case when hh10 = 0 then null
            else pass_veh / hh10 end) as veh_hh,
        (case when hh10 = 0 then null
            else fuelperday / hh10 end) as fuel_hh,
        (case when hh10 = 0 then null
            else co2perday / hh10 end) as co2_hh
    from smooth_operator
);

-- join smooth normal clean to polygons
drop table if exists nice_squares15;
create table nice_squares15 as (
    select 
        wkb_geometry as geom,
        grid_id,
        count,
        pop10,
        hh10,
        pass_veh,
        rate_veh_hi,
        rate_veh_lo,
        veh_person,
        veh_hh,
        fuel_person,
        fuel_hh,
        co2_person,
        co2_hh
    from grid as g as g
    join ( 
        select * from normal_and_smooth
        where
            pop10 > 15
            and hh10 > 5
            and pass_veh > 1
    ) as n
    on g.g250m_id = n.grid_id
);


-- join smooth normal clean to polygons
drop table if exists nice_squares25;
create table nice_squares25 as (
    select 
        wkb_geometry as geom,
        grid_id,
        count,
        pop10,
        hh10,
        pass_veh,
        rate_veh_hi,
        rate_veh_lo,
        veh_person,
        veh_hh,
        fuel_person,
        fuel_hh,
        co2_person,
        co2_hh
    from grid as g
    join ( 
        select * from normal_and_smooth
        where
            pop10 > 25
            and hh10 > 5
            and pass_veh > 1
    ) as n
    on g.g250m_id = n.grid_id
);

-- join smooth normal clean to polygons
drop table if exists nice_squares50;
create table nice_squares50 as (
    select 
        wkb_geometry as geom,
        grid_id,
        count,
        pop10,
        hh10,
        pass_veh,
        rate_veh_hi,
        rate_veh_lo,
        veh_person,
        veh_hh,
        fuel_person,
        fuel_hh,
        co2_person,
        co2_hh
    from grid as g
    join ( 
        select * from normal_and_smooth
        where
            pop10 > 50
            and hh10 > 5
            and pass_veh > 1
    ) as n
    on g.g250m_id = n.grid_id
);
