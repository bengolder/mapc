create table selected_neighborhoods as (
select * from neighborhoods
where
    town in (
        'CONCORD',
        'BOLTON'
    ) or "name" = 'BACK BAY'
)
;
