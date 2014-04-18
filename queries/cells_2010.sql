create table cells_2010 as (
    select
      g250m_id,
      muni_id,
      quarter,
      pass_veh,
      glpdaypass,
      co2eqv_day
    from squares
    where
        quarter like '2010%'
)
;


