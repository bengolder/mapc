-- here we assume that we have already copied in 3 datasets:
-- grid_quarters_public and rae_public
-- as well as the grid shapefile (using ogr2ogr into a table named 'grid')
-- and the grid attributes (as shown below)
copy grid_atts from
    '/home/bgolder/projects/mapc/data/Tabular/grid250m_attributes.csv'
    delimiter ','
    csv header
;


---------------------------------------

-- create averages of the 2010 quarters
drop table if exists avgs_2010;
create table avgs_2010 as (
    select
        g250m_id,
        ( case when sum(pass_veh) = 0 then null
            else sum( mipdaypass * pass_veh ) / sum(pass_veh) 
            end ) as vmt,
        ( case when sum(pass_veh) = 0 then null
            else sum( mpg_eff * pass_veh ) / sum(pass_veh) 
            end ) as mpg_eff,
        avg(veh_lo) as veh_lo,
        avg(veh_hi) as veh_hi,
        avg(pass_veh) as pass_veh
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
        d.vmt,
        d.mpg_eff
    from grid as p
    join avgs_2010 as d on d.g250m_id = p.g250m_id
    join grid_atts as a on a.g250m_id = p.g250m_id
);

-- create a spatial index for smoothing lookups
drop index if exists pt_index;
create index pt_index on avgs_pts using gist ( pt );

-- register the index for future lookups
vacuum (analyze) avgs_pts;


-------------------------------------------------------------------------------
---------- THIS QUERY IS QUERANTINED BECAUSE IT GAVE WEIRD RESULTS ------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- find things that values that seem too extreme for their context and set them
-- to null
drop table if exists reasonable_vehicles;
create table reasonable_vehicles as (
    select
        a.grid_id, a.pt,
        min(a.pop10) as pop10,
        min(a.hh10) as hh10,
        min(a.veh_lo) as veh_lo,
        min(a.veh_hi) as veh_hi,
        min(a.pass_veh) as pass_veh,
        min(a.vmt) as vmt,
        min(a.mpg_ef) as mpg_eff
    from avgs_pts as a 
    join avgs_pts as b on ST_DWithin(a.pt, b.pt, 360) 
        and a.grid_id != b.grid_id
    group by a.grid_id, a.pt, 
    having 
        min(a.pop10) > 1
        and min(a.hh10) > 1
        and sum(b.pop10) > 1
        and ( min(a.pass_veh) / min(a.pop10) ) - ( sum(b.pass_veh * b.pop10) / sum(b.pop10) ) < 0.5
);
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

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
        ( case when sum(b.pass_veh) = 0 then null
            else sum( b.vmt * b.pass_veh ) / sum(b.pass_veh) 
            end ) as vmt,
        ( case when sum(b.pass_veh) = 0 then null
            else sum( b.mpg_eff * b.pass_veh ) / sum(b.pass_veh) 
            end ) as mpg_eff
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
        vmt,
        mpg_eff,

        -- estimates of fuel and co2 based on 
        -- mpg and vmt
        (case when mpg_eff = 0 then null
            else ((1/mpg_eff) * vmt) end) as fuel_day_veh,
        (case when mpg_eff = 0 then null
            else ((1/mpg_eff) * vmt * 20) end) as co2_day_veh,

        -- vehicle rates
        (case when pass_veh = 0 then null
            else veh_hi / pass_veh end) as rate_veh_hi,
        (case when pass_veh = 0 then null
            else veh_lo / pass_veh end) as rate_veh_lo,
        (case when pop10 = 0 then null
            else pass_veh / pop10 end) as veh_person,
        (case when hh10 = 0 then null
            else pass_veh / hh10 end) as veh_hh,

        -- vmt is already per vehicle
        -- here we get the estimated total vmt for all vehicles in square
        -- then divide that per person
        (case when pop10 = 0 then null
            else (vmt * pass_veh) / pop10 end) as vmt_person,
        (case when hh10 = 0 then null
            else (vmt * pass_veh) / hh10 end) as vmt_hh,

        -- estimate fuel per person and hh based on vmt
        (case when pop10 = 0 or mpg_eff = 0 then null
            else ((1/mpg_eff) * vmt * pass_veh) / pop10 end) as fuel_day_person,
        (case when hh10 = 0 or mpg_eff = 0 then null
            else ((1/mpg_eff) * vmt * pass_veh) / hh10 end) as fuel_day_hh

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

        -- vehicles and vehicle rates
        pass_veh,
        veh_person,
        veh_hh,
        rate_veh_hi,
        rate_veh_lo,

        -- vmt and associated figures
        vmt,
        vmt_person,
        vmt_hh,

        -- fuel efficiency and estimated fuel consumption
        mpg_eff,
        fuel_day_veh,
        fuel_day_person,
        fuel_day_hh,

        co2_day_veh

    from grid as g 
    join ( 
        select * from normal_and_smooth
        where
            pop10 > 15
            and hh10 > 1
            and pass_veh > 1
    ) as n
    on g.g250m_id = n.grid_id
);


drop table if exists nice_pts;
create table nice_pts as (
    select
        ST_Centroid(geom) as pt,
        grid_id,
        count,
        pop10,
        hh10,
        -- vehicles and vehicle rates
        pass_veh,
        veh_person,
        veh_hh,
        rate_veh_hi,
        rate_veh_lo,
        -- vmt and associated figures
        vmt,
        vmt_person,
        vmt_hh,

        -- fuel efficiency and estimated fuel consumption
        mpg_eff,
        fuel_day_veh,
        fuel_day_person,
        fuel_day_hh,

        co2_day_veh

    from nice_squares15
);

-- aggregate by block group, joining the deomgraphic block data in the process
-- block group shapefile must be loaded
-- create a spatial index on smooth operator to make the spatial join faster
drop index if exists smooth_operator_idx;
create index smooth_operator_idx on smooth_operator using gist ( pt ); 

drop index if exists block_groups_idx;
create index block_groups_idx on block_groups using gist ( wkb_geometry ); 

-- register the index
vacuum (analyze) smooth_operator;
vacuum (analyze) block_groups;

drop table if exists block_group_agg;
-- this table pulls in all points which are within 10 meters of the boundaries of a block group and sums 
-- the vehicle and population data. number of grid cells included is in count. 
-- Some grid cells may be counted in several block groups if they're close to the border.
create table block_group_agg as (
    select ogc_fid, 
        wkb_geometry, 
        geoid10, 
        count(pt) as count,
        se_t057_00 as med_hh_inc,
        se_t117_00 as pop_pov_stat,
        se_t117_01 as pop_pov_under_50_perc,
        se_t117_02 as pop_pov_50_74_perc,
        se_t117_03 as pop_pov_75_99_perc,
        se_t117_04 as pop_pov_100_149_perc,
        se_t117_05 as pop_pov_150_199,
        se_t117_06 as pop_pov_200,
        sum(pop10) as pop10, 
        sum(hh10) as hh10, 

        -- number of vehicles and associated values
        sum(pass_veh) as pass_veh,
        sum(pass_veh) / sum(pop10) as veh_person,
        sum(pass_veh) / sum(hh10) as veh_hh,
        sum(veh_lo) as veh_lo, 
        sum(veh_hi) as veh_hi, 
        sum(veh_hi) / sum(pass_veh) as rate_veh_hi,
        sum(veh_lo) / sum(pass_veh) as rate_veh_lo,

        -- vmt and associated figures
        -- vmt (vehicle miles per vehicle per day) weighted by number of vehicles
        sum( vmt * pass_veh ) / sum(pass_veh) as vmt,

        -- weighted vmt divided by population
        ( ( sum( vmt * pass_veh ) / sum(pass_veh) ) * sum(pass_veh) ) 
            / sum(pop10) as vmt_person,

        -- weighted vmt divided by households
        ( ( sum( vmt * pass_veh ) / sum(pass_veh) ) * sum(pass_veh) ) 
            / sum(hh10) as vmt_hh,

        -- fuel efficiency and estimated fuel consumption

        -- fuel efficiency weighted by number of vehicles
        sum(mpg_eff * pass_veh) / sum(pass_veh) as mpg_eff,

        -- fuel per day per vehicle
        -- this is the inverse of mpg (gpm) multiplied by vmt
        (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) )
            as fuel_day_veh,

        -- co2 per day per vehicle
        -- this is the same as  but multiplied by 20
        (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) *
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) * 20 
            as c02_day_veh,


        -- fuel per person per day
        -- fuel per day per vehicle 
        -- times number of vehicles (so total fuel per day)
        -- divided by population
        ( (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) ) * sum(pass_veh) /
            sum(pop10) 
            as fuel_day_person,

        -- fuel per day per household
        -- same calculation as above, but substuting households for population
        ( (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) ) * sum(pass_veh)/
            sum(hh10) 
            as fuel_day_hh

    from smooth_operator as p
    join block_groups as b
        on ST_DWithin(p.pt, b.wkb_geometry, 10)
    group by ogc_fid, geoid10
    having
        sum(pop10) > 0
        and sum(hh10) > 0
        and sum(pass_veh) > 0
        and sum( vmt * pass_veh ) / sum(pass_veh) > 0
        and sum(mpg_eff * pass_veh) / sum(pass_veh) > 0
);



-- LOAD TOWNS

-- give them a single name attribute
alter table towns add column name character varying;
update towns set name = (
    case when town is null then neigh_nam
    else town
    end );

-- add spatial index index to towns
drop index if exists towns_idx;
create index towns_idx on towns using gist ( wkb_geometry ); 

-- register spatial index
vacuum (analyze) towns;

drop table if exists town_agg;
-- this table pulls in all points which are within 10 meters of the boundaries of a town and sums 
-- the vehicle and population data. number of grid cells included is in count. 
-- Some grid cells may be counted in several towns if they're close to the border.
create table town_agg as (
    select ogc_fid, 
        wkb_geometry, 
        name,
        objectid, 
        count(pt) as count,
        sum_hh_new,
        sum_tot_po,
        sum_pov_50,
        sum_pov_15,
        sum_pov_u2,
        sum_pov_a2,
        inc_factor,
        hh_new,
        hh_inc_wei,
        sum(pop10) as pop10, 
        sum(hh10) as hh10, 

        -- number of vehicles and associated values
        sum(pass_veh) as pass_veh,
        sum(pass_veh) / sum(pop10) as veh_person,
        sum(pass_veh) / sum(hh10) as veh_hh,
        sum(veh_lo) as veh_lo, 
        sum(veh_hi) as veh_hi, 
        sum(veh_hi) / sum(pass_veh) as rate_veh_hi,
        sum(veh_lo) / sum(pass_veh) as rate_veh_lo,

        -- vmt and associated figures
        -- vmt (vehicle miles per vehicle per day) weighted by number of vehicles
        sum( vmt * pass_veh ) / sum(pass_veh) as vmt,

        -- weighted vmt divided by population
        ( ( sum( vmt * pass_veh ) / sum(pass_veh) ) * sum(pass_veh) ) 
            / sum(pop10) as vmt_person,

        -- weighted vmt divided by households
        ( ( sum( vmt * pass_veh ) / sum(pass_veh) ) * sum(pass_veh) ) 
            / sum(hh10) as vmt_hh,

        -- fuel efficiency and estimated fuel consumption

        -- fuel efficiency weighted by number of vehicles
        sum(mpg_eff * pass_veh) / sum(pass_veh) as mpg_eff,

        -- fuel per day per vehicle
        -- this is the inverse of mpg (gpm) multiplied by vmt
        (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) )
            as fuel_day_veh,

        -- co2 per day per vehicle
        -- this is the same as  but multiplied by 20
        (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) *
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) * 20 
            as c02_day_veh,


        -- fuel per person per day
        -- fuel per day per vehicle 
        -- times number of vehicles (so total fuel per day)
        -- divided by population
        ( (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) ) * sum(pass_veh) /
            sum(pop10) 
            as fuel_day_person,

        -- fuel per day per household
        -- same calculation as above, but substuting households for population
        ( (1 / ( sum(mpg_eff * pass_veh) / sum(pass_veh) )) * 
            ( sum( vmt * pass_veh ) / sum(pass_veh) ) ) * sum(pass_veh)/
            sum(hh10) 
            as fuel_day_hh

    from smooth_operator as p
    join towns as b
        on ST_DWithin(p.pt, b.wkb_geometry, 10)
    group by ogc_fid, objectid
    having
        sum(pop10) > 0
        and sum(hh10) > 0
        and sum(pass_veh) > 0
        and sum( vmt * pass_veh ) / sum(pass_veh) > 0
        and sum(mpg_eff * pass_veh) / sum(pass_veh) > 0
);

