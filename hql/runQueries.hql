SET hive.auto.convert.join=false;

ADD JAR hdfs:///user/hive/udf_jars/esri-geometry-api-2.0.0.jar;
ADD JAR hdfs:///user/hive/udf_jars/spatial-sdk-hive-2.1.0-SNAPSHOT.jar;
ADD JAR hdfs:///user/hive/udf_jars/spatial-sdk-json-2.1.0-SNAPSHOT.jar;

create temporary function ST_AsText as 'com.esri.hadoop.hive.ST_AsText';
create temporary function ST_Point as 'com.esri.hadoop.hive.ST_Point';
create temporary function ST_Contains as 'com.esri.hadoop.hive.ST_Contains';

SELECT counties.name, count(*) cnt FROM counties
JOIN earthquakes
WHERE ST_Contains(counties.boundaryshape, ST_Point(earthquakes.longitude, earthquakes.latitude))
GROUP BY counties.name
ORDER BY cnt desc;
