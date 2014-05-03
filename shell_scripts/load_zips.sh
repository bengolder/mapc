export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/zipcodes_shp/zipcodes.shp' \
    -nlt MULTIPOLYGON \
    -nln 'zipcode_polys'
export PGCLIENTENCODING=UTF8
