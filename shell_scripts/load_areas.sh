export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/matowns_wbostonneigh/matowns_wbostonneigh.shp' \
    -nlt MULTIPOLYGON \
    -nln 'neighborhoods'

ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/censusblocks/ma_bgs_vehicle_data.shp' \
    -nlt POLYGON \
    -nln 'block_groups'

ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/MA_bgs_income_poverty_2010/MA_bgs_income_poverty_2010/MA_bgs_income_poverty_2010.shp' \
    -nlt MULTIPOLYGON \
    -nln 'bg_poverty'

export PGCLIENTENCODING=UTF8

