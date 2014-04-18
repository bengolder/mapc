create table clean_smooth_norm as (
    select 
        *
    from smooth_norm_2010
    where pop10 > 0
    and count >= 4
)
;
