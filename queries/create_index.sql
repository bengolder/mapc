create index pt_index on avgs_pts using gist ( pt );
vacuuum (analyze) avgs_pts;
