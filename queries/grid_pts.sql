create table grid_pts as (
    select
        g250m_id as grid_id,
        ST_Centroid(wkb_geometry) as pt
    from grid
)
;

