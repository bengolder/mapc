-- This is the full query process to extract 
-- information by zipcode from the vehicle registration location table
-- It begins with rae_public, a table loaded from csv


-- first, for each record we want to get the number of days that occur within
-- 2010



-- create a subtable from rae that only includes the records we are interested in.
drop table if exists rae_2010;
create table rae_2010 as (
	select * from rae
	where
		-- overlaps some portion of 2010
		(date '2010-01-01', date '2010-12-31') overlaps (start_date, end_date) and
		-- is a passenger vehicle
		owner_type = 1 and
		-- is not a motorcycle
		mcycle is null and
		-- it has a Massachusetts zip code (or the null zip)
		( veh_zip in (select zcta5ce10 from zipcode_w_acs) or
		 veh_zip = '00000' )
);


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
    from rae_2010
);

-- using lookup tables to set mpg for manually fixed make and models.
update rae_2010
	set mpg2008 = b.mpg2008, mpg_adj = b.mpg2008
from mpg_update as b
where 
	rae_2010.model_year = b.model_year and 
	rae_2010.make = b.make and 
	rae_2010.model = b.model;

-- set the miles per day as null if they have none 
-- (this accounts for those with invalid mileage estimates)
update rae_2010
	set mi_per_day = null
where mi_per_day = 0;

drop table if exists rae_vmt_zip;
create table rae_vmt_zip as (
	select
		veh_zip as zip,
		count(*),
		avg(mi_per_day)
	from rae_2010
	group by veh_zip
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
            ( select 
            	sum(r.mpg_adj * d.days_2010 * r.mi_per_day) / 
            	sum(d.days_2010 * r.mi_per_day)
              from rae_days as d
        		left join rae_2010 as r
        		on d.record_id = r.record_id )

        else r.mpg_adj end ) as mpg_adj,

        -- if there is no valid mileage estimate, we will use the average
        -- number of miles driven per record in 2010
        ( case when insp_match is false then
        
            -- get the fleet mean miles traveled in 2010
            ( select
            	avg( r.mi_per_day )
              from rae_days as d
        		left join rae_2010 as r
        		on d.record_id = r.record_id )
            
        else r.mi_per_day end ) as miles_per_day,
        
        r.veh_zip as zip
    from rae_days as d
        left join rae_2010 as r
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
