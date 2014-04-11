create table grid_pts as (
    select 
        g250m_id as id,
        ST_Centroid(wkb_geometry) as point
    from grid
)
