export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/towns_poverty_final/towns_poverty_final.shp' \
    -nlt MULTIPOLYGON \
    -nln 'towns'
export PGCLIENTENCODING=UTF8
