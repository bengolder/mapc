create table squares as (
    select
        g.wkb_geometry as geom,
        g.municipal as municipality,
        g.muni_id,
        q.*
    from 
        grid_quarters_public as q
        left outer join grid as g
        on q.g250m_id = g.g250m_id
    )
;
drop table if exists grid_quarters_public cascade;
drop table if exists grid cascade;
