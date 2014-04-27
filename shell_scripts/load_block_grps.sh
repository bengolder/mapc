export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"user=postgres password=postgres host=localhost dbname=mapc" \
    '/home/bgolder/projects/mapc/data/MA_bgs_income_poverty_2010/MA_bgs_income_poverty_2010/MA_bgs_income_poverty_2010.shp' \
    -nlt POLYGON \
    -nln 'block_groups'
export PGCLIENTENCODING=UTF8
