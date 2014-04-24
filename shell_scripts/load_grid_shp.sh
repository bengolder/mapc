export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/veh_census/grid_250m_shell.shp' \
    -nlt POLYGON \
    -nln 'grid'
export PGCLIENTENCODING=UTF8

