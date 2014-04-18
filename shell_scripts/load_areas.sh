export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"host=localhost dbname=mapc" \
    ./data/metro_boston_w_neighborhoods/metro_boston_w_neighborhoods.shp \
    -nlt MULTIPOLYGON \
    -nln neighborhoods
export PGCLIENTENCODING=UTF8

