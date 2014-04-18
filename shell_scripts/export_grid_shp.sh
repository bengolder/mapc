ogr2ogr \
    ./data/sample_points.shp \
    PG:"host=localhost dbname=mapc" \
    -sql "select * from sample_points"


