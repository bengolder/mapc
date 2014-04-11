create table sample_points as (
    select 
        p.id as id,
        p.point as pt,
        n.town as town,
        n.name as name,
        n.objectid_1 as neighbrhd_id
    from grid_pts as p
    join selected_neighborhoods as n
    on
    ST_Contains( n.wkb_geometry, p.point )
)
;

