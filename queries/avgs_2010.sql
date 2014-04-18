create table avgs_2010 as (
    select
      g250m_id,
      avg(pass_veh) as pass_veh,
      avg(glpdaypass) as fuelperday,
      avg(co2eqv_day) as co2perday
    from cells_2010
    group by g250m_id
)
;

