drop table if exists smooth_norm_2010;
create table smooth_norm_2010 as (
    select
        a.pt as pt,
        a.grid_id as grid_id,
        a.count as count,
        (case when g.pop10 = 0 then null
            else a.pass_veh / g.pop10 end) as veh_person,
        (case when g.pop10 = 0 then null
            else a.fuelperday / g.pop10 end) as fuel_person,
        (case when g.pop10 = 0 then null
            else a.co2perday / g.pop10 end) as co2_person,
        g.pop10 as pop10
    from smoothed_pts as a
    join grid_atts as g
    on a.grid_id = g.g250m_id
)
