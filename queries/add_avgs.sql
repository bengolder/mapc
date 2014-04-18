create table avgs_pts as (
    select
        grid_id,
        pt,
        pass_veh,
        fuelperday,
        co2perday
    from grid_pts as p
    join avgs_2010 as d
    on d.g250m_id = p.grid_id
)
;
