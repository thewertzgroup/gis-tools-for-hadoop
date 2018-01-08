ADD JAR hdfs:///user/hive/udf_jars/esri-geometry-api-2.0.0.jar;
ADD JAR hdfs:///user/hive/udf_jars/spatial-sdk-hive-2.1.0-SNAPSHOT.jar;
ADD JAR hdfs:///user/hive/udf_jars/spatial-sdk-json-2.1.0-SNAPSHOT.jar;

create temporary function ST_AsText as 'com.esri.hadoop.hive.ST_AsText';


DROP TABLE IF EXISTS earthquakes;
DROP TABLE IF EXISTS counties;

CREATE EXTERNAL TABLE IF NOT EXISTS earthquakes
(
	earthquake_date STRING,
	latitude DOUBLE,
	longitude DOUBLE,
	depth DOUBLE,
	magnitude DOUBLE,
	magtype string,
	mbstations string,
	gap string,
	distance string,
	rms string,
	source string,
	eventid string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 'hdfs:///user/christoph/gis/earthquakes'
;

SELECT * FROM earthquakes LIMIT 5;

CREATE EXTERNAL TABLE IF NOT EXISTS counties
(
	area string,
	perimeter string,
	state string,
	county string,
	name string,
	boundaryshape binary
)
ROW FORMAT SERDE 'com.esri.hadoop.hive.serde.EsriJsonSerDe'
STORED AS INPUTFORMAT 'com.esri.json.hadoop.EnclosedEsriJsonInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 'hdfs:///user/christoph/gis/california-counties'
;

--SELECT area, perimeter, state, county, name, ST_AsText(boundaryshape) FROM counties LIMIT 5;
SELECT area, perimeter, state, county, name FROM counties LIMIT 5;
