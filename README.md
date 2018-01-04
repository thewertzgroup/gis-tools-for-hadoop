# gis-tools-for-hadoop

https://mapzen.com/data/metro-extracts/

Search for New York ---> Export

https://mapzen.com/data/metro-extracts/metro/new-york_new-york/

All Starbucks locations in the world

https://gist.githubusercontent.com/dankohn/09e5446feb4a8faea24f/raw/59154601e80ee2f3e2c7433f55f6fa047dddb6be/starbucks_us_locations.csv

US States:

https://github.com/shawnbot/topogram/blob/master/data/us-states.geojson

Esri Binning:

https://github.com/Esri/gis-tools-for-hadoop/wiki/Aggregating-CSV-Data-%28Spatial-Binning%29

## Create and add the jars

```
git clone https://github.com/Esri/geometry-api-java
git clone https://github.com/Esri/gis-tools-for-hadoop
git clone https://github.com/Esri/spatial-framework-for-hadoop

hdfs dfs -mkdir /user/hive/udf_jars
hdfs dfs -put esri-geometry-api-2.0.0.jar /user/hive/udf_jars
hdfs dfs -put spatial-sdk-json-2.1.0-SNAPSHOT.jar /user/hive/udf_jars
hdfs dfs -put spatial-sdk-hive-2.1.0-SNAPSHOT.jar /user/hive/udf_jars
```
## Prepare hive

```
set hive.auto.convert.join=false;

add jar hdfs:///user/hive/udf_jars/esri-geometry-api-2.0.0.jar;
add jar hdfs:///user/hive/udf_jars/spatial-sdk-json-2.1.0-SNAPSHOT.jar;
add jar hdfs:///user/hive/udf_jars/spatial-sdk-hive-2.1.0-SNAPSHOT.jar;

create temporary function ST_Point as 'com.esri.hadoop.hive.ST_Point';
create temporary function ST_Contains as 'com.esri.hadoop.hive.ST_Contains';

drop table if exists earthquakes;
drop table if exists counties;

CREATE TABLE earthquakes (earthquake_date STRING, latitude DOUBLE, longitude DOUBLE, depth DOUBLE, magnitude DOUBLE,
    magtype string, mbstations string, gap string, distance string, rms string, source string, eventid string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
```

## Define a schema for the California counties data (the counties data is stored as Enclosed JSON)

```
CREATE TABLE counties (Area string, Perimeter string, State string, County string, Name string, BoundaryShape binary)         
ROW FORMAT SERDE 'com.esri.hadoop.hive.serde.EsriJsonSerDe'
STORED AS INPUTFORMAT 'com.esri.json.hadoop.EnclosedEsriJsonInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';
Load data into the respective tables:

LOAD DATA INPATH 'earthquake-demo/earthquake-data/earthquakes.csv' OVERWRITE INTO TABLE earthquakes;
LOAD DATA INPATH 'earthquake-demo/counties-data/california-counties.json' OVERWRITE INTO TABLE counties;
```

## Run the demo analysis

```
SELECT counties.name, count(*) cnt FROM counties
JOIN earthquakes
WHERE ST_Contains(counties.boundaryshape, ST_Point(earthquakes.longitude, earthquakes.latitude))
GROUP BY counties.name
ORDER BY cnt desc;
```

## Review the output

```
Total MapReduce CPU Time Spent: 15 seconds 590 msec
OK
Kern            36
San Bernardino  35
Imperial        28
Inyo            20
Los Angeles     18
Riverside       14
Monterey        14
Santa Clara     12
Fresno          11
San Benito      11
San Diego       7
Santa Cruz      5
San Luis Obispo 3
Ventura         3
Orange          2
San Mateo       1
Time taken: 67.654 seconds, Fetched: 16 row(s)
hive>
```
