-- spatial smoothing query
-- create an value for each of the points,
-- based on the value of all points within 
-- 360 meters
create table smoothed_pts as (
select
    a.grid_id,
    a.pt,
    count(b.pt) as count,
    avg(b.pass_veh) as pass_veh,
    avg(b.fuelperday) as fuelperday,
    avg(b.co2perday) as co2perday
from avgs_pts as a 
join avgs_pts as b
    on ST_DWithin(a.pt, b.pt, 360)
group by a.grid_id, a.pt
);
