export PGCLIENTENCODING=LATIN1 
ogr2ogr \
    -lco PRECISION=NO \
    -t_srs EPSG:26986 \
    -f 'PostgreSQL' \
    PG:"host=localhost dbname=mapc" \
    ./data/MassVehicleCensusData_20130310/grid_250m_shell.shp \
    -nlt POLYGON \
    -nln grid
export PGCLIENTENCODING=UTF8

