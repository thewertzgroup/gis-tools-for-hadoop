# gis-tools-for-hadoop

## Key Terms
* **GIS**: Geographic Information System
* **ESRI**: A company whose GIS mapping software is some of the most powerful mapping and spatial data analytics technology available.
* **Esri JSON**: A proprietary JSON format for GIS data created by Esri.
* **GeoJSON**: <a href="http://geojson.org/" target="_blank">http://geojson.org/</a> In 2015, the Internet Engineering Task Force (IETF), in conjunction with the original specification authors, formed a GeoJSON WG to standardize GeoJSON. RFC 7946 was published in August 2016 and is the new standard specification of the GeoJSON format, replacing the 2008 GeoJSON specification.
* **Shapefile**: <a href="https://en.wikipedia.org/wiki/Shapefile" target="_blank">https://en.wikipedia.org/wiki/Shapefile</a> The shapefile format is a popular geospatial vector data format for geographic information system (GIS) software. It is developed and regulated by Esri as a (mostly) open specification for data interoperability among Esri and other GIS software products.

## Step 1: Build Jars and Add to HDFS

* If you need to install Apache Maven: <a href="https://maven.apache.org/install.html" target="_blank">https://maven.apache.org/install.html</a>
* Esri examples and sample data: <a href="https://github.com/Esri/gis-tools-for-hadoop" target="_blank">https://github.com/Esri/gis-tools-for-hadoop</a>

```
git clone https://github.com/Esri/geometry-api-java
git clone https://github.com/Esri/spatial-framework-for-hadoop

hdfs dfs -mkdir /user/hive/udf_jars
hdfs dfs -put esri-geometry-api-2.0.0.jar /user/hive/udf_jars
hdfs dfs -put spatial-sdk-json-2.1.0-SNAPSHOT.jar /user/hive/udf_jars
hdfs dfs -put spatial-sdk-hive-2.1.0-SNAPSHOT.jar /user/hive/udf_jars
```

## Step 2: Get Sample Data and GeoJSON Files

```
wget https://raw.githubusercontent.com/Esri/gis-tools-for-hadoop/master/samples/data/counties-data/california-counties.json
wget https://raw.githubusercontent.com/Esri/gis-tools-for-hadoop/master/samples/data/earthquake-data/earthquakes.csv
```

```
hdfs dfs -mkdir gis
hdfs dfs -mkdir gis/california-counties
hdfs dfs -mkdir gis/earthquakes
hdfs dfs -put california-counties.csv gis/california-counties
hdfs dfs -put earthquakes.csv gis/earthquakes
```

## Step 3: Build ogr2ogr to conver Shapefiles to GeoJSON

Building ogr2ogr to convert Shape files to GEOJson:

<a href="https://github.com/wavded/ogre/wiki/Compiling-a-recent-ogr2ogr-from-source-on-CentOS-(RHEL)" target="_blank">href="Compiling a recent ogr2ogr from source on CentOS (RHEL)</a>

* wget http://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz
* wget http://download.osgeo.org/proj/proj-4.9.3.tar.gz

## Step 4: Additional Data Sets

https://mapzen.com/data/metro-extracts/

Search for New York ---> Export

https://mapzen.com/data/metro-extracts/metro/new-york_new-york/

Shapefile 2 Geo JSON:

new-york_new-york.imposm-shapefiles]$ ogr2ogr -f GeoJSON -t_srs crs:84 new-york_new-york_osm_places.geojson new-york_new-york_osm_places.shp

All Starbucks locations in the world

https://gist.githubusercontent.com/dankohn/09e5446feb4a8faea24f/raw/59154601e80ee2f3e2c7433f55f6fa047dddb6be/starbucks_us_locations.csv

US States:

https://github.com/shawnbot/topogram/blob/master/data/us-states.geojson

Esri Binning:

https://github.com/Esri/gis-tools-for-hadoop/wiki/Aggregating-CSV-Data-%28Spatial-Binning%29

Precision of Accruacy of Lat / Long:

https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude/8674#8674

Big Data and Analytics: A Conceptual Overview

http://proceedings.esri.com/library/userconf/proc15/tech-workshops/tw_445-253.pdf

ll geometry-api-java/target/esri-geometry-api-2.0.0.jar

ll spatial-framework-for-hadoop/hive/target/spatial-sdk-hive-2.1.0-SNAPSHOT.jar

ll spatial-framework-for-hadoop/json/target/spatial-sdk-json-2.1.0-SNAPSHOT.jar

## Reverse Geocoding: Point in polygon lat/long --> zipcode GeoJSON boundaries

https://www.census.gov/cgi-bin/geo/shapefiles2010/main

```
[ztrew@foo zipcode]$cat ../bin/ogr2ogr.sh
ogr2ogr -f GeoJSON -t_srs crs:84 ${1}.geojson ${1}.shp
[ztrew@foo zipcode]$ ../bin/ogr2ogr.sh tl_2010_us_zcta510
```

```
set hive.auto.convert.join=false;

add jar hdfs:///user/hive/udf_jars/esri-geometry-api-2.0.0.jar;
add jar hdfs:///user/hive/udf_jars/spatial-sdk-json-2.1.0-SNAPSHOT.jar;
add jar hdfs:///user/hive/udf_jars/spatial-sdk-hive-2.1.0-SNAPSHOT.jar;

create temporary function ST_Point as 'com.esri.hadoop.hive.ST_Point';
create temporary function ST_Contains as 'com.esri.hadoop.hive.ST_Contains';
create temporary function ST_GeomFromGeoJson as 'com.esri.hadoop.hive.ST_GeomFromGeoJson';
create temporary function ST_Intersects as 'com.esri.hadoop.hive.ST_Intersects';
create temporary function ST_AsText as 'com.esri.hadoop.hive.ST_AsText';
create temporary function ST_AsGeoJson as 'com.esri.hadoop.hive.ST_AsGeoJson';
create temporary function ST_Bin as 'com.esri.hadoop.hive.ST_Bin';
create temporary function ST_BinEnvelope as 'com.esri.hadoop.hive.ST_BinEnvelope';

DROP TABLE IF EXISTS zipcode;

CREATE EXTERNAL TABLE IF NOT EXISTS zipcode (
        ZCTA5CE10       STRING,
        GEOID10         STRING,
        CLASSFP10       STRING,
        MTFCC10         STRING,
        FUNCSTAT10      STRING,
        ALAND10         STRING,
        AWATER10        STRING,
        INTPTLAT10      STRING,
        INTPTLON10      STRING,
        geometry        binary
)
ROW FORMAT SERDE 'com.esri.hadoop.hive.serde.GeoJsonSerDe'
STORED AS INPUTFORMAT 'com.esri.json.hadoop.EnclosedGeoJsonInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/user/ztrew/zipcode';

select ZCTA5CE10 from zipcode limit 5;

SELECT z.ZCTA5CE10, s.addr, s.long, s.lat FROM zipcode z
JOIN starbucks s
WHERE ST_Contains(z.geometry, ST_Point(s.long, s.lat))
limit 5;
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
