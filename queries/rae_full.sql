-- This is the full query process to extract 
-- information by zipcode from the vehicle registration location table
-- It begins with rae_public, a table loaded from csv


-- first, for each record we want to get the number of days that occur within
-- 2010


-- create a table for records that fall within the desired date range
-- grab only passenger vehicles
-- truncate the start and end dates to the year of 2010, and get the number of
-- days that they overlap with 2010
drop table if exists rae_days;
create table rae_days as (
    select
        record_id,
        -- truncate to 2010 
        greatest(date '2010-01-01', start_date) as days_start, 
        least(date '2010-12-31', end_date) as days_end, 
        -- to get the number of days
        least(date '2010-12-31', end_date) - 
            greatest(date '2010-01-01', start_date
            ) as days_2010
    from rae_public
    where
        -- only get records that overlap 2010
        (date '2010-01-01', date '2010-12-31') overlaps (start_date, end_date) and
        -- only use passenger vehicle
        owner_type = 1
);

drop table if exists rae_nonnull;
create table rae_nonnull as (
    select
        r.record_id,
        r.vin_id,
        d.days_2010 as days_2010,

        -- if there is no mpg value, then we will use the average mpg per mile
        -- driven
        ( case when r.mpg_adj is null then
            -- get mean adjusted miles per gallon for average mile driven
            sum(r.mpg_adj * d.days_2010 * r.mi_per_day) / 
            sum(d.days_2010 * r.mi_per_day)
        else r.mpg_adj end ) as mpg_adj,

        -- if there is no valid mileage estimate, we will use the average
        -- number of miles driven per record in 2010
        ( case when insp_match is null then
            -- get the fleet mean miles traveled in 2010
            sum( d.days_2010 * r.mi_per_day ) /
            count(*)
        else r.mi_per_day end ) as miles_per_day,

        r.veh_zip as zip

    from rae_days as d
        left join rae_public as r
        on d.record_id = r.record_id
);

-- aggregate the total vehicle miles accumulated during 2010, 
-- along with the number of gallons and fuel efficiency
drop table if exists record_stats;
create table record_stats as (
    select
        *,
        ( 1 / mpg_adj ) * miles_per_day as gallons_per_day,
        ( 1 / mpg_adj ) * miles_per_day * days_2010 as gallons_2010,
        miles_per_day * days_2010 as miles_2010
    from rae_nonnull
);




