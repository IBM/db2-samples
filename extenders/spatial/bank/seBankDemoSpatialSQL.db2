----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2000 - 2014
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Product Name:     DB2 Spatial Extender 10.5 
--
-- Source File Name: seBankDemoSpatialSQL.db2
--
-- Version:          10.5.1
--
-- Description:      examples spatial UDF's from the Spatial Extender User's Guide
--
--
-- For more information about the DB2 Spatial Extender Bank Demo scripts,
-- see the seBankDemoREADME.txt file.
--
-- For more information about DB2 SE, see the "DB2 Spatial Extender User Guide".
--
-- For the latest information on DB2 Spatial Extender and the Bank Demo
-- refer to the DB2 Spatial Extender website at
--     http://www.software.ibm.com/software/data/spatial/db2spatial
----------------------------------------------------------------------------
--connect to se_bank;
--===============================================================
-- List Current Function Path
--===============================================================
--  VALUES(CURRENT FUNCTION PATH);

--===============================================================
-- Update Current Function Path
--===============================================================
--SET CURRENT FUNCTION PATH = CURRENT FUNCTION PATH, db2gse;

--===============================================================
-- ST_Area(geometry)
--===============================================================
--!db2se drop_srs se_bank -srsName new_york1983;

--!db2se create_srs se_bank  -srsId 4000 -srsName new_york1983 -xOffset 0 -yOffset 0 -xScale 1 -yScale 1 -coordsysName NAD_1983_StatePlane_New_York_East_FIPS_3101_Feet;

--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons (id, geometry) 
--VALUES
--    (1, ST_Polygon('polygon((0 0, 0 10, 10 10, 10 0, 0 0))', 4000) ),    
--    (2, ST_Polygon('polygon((20 0, 30 20, 40 0, 20 0 ))', 4000) ),
--    (3, ST_Polygon('polygon((20 30, 25 35, 30 30, 20 30))', 4000));

--SELECT id, ST_Area(geometry) AS area
--FROM   sample_polygons;

----The following does the same as the above only with method notation
--SELECT id, geometry..ST_AREA AS area
--FROM   sample_polygons;

--SELECT id, 
--       ST_Area(geometry) square_feet,           
--       ST_Area(geometry, 'METER') square_meters,           
--       ST_Area(geometry, 'STATUTE MILE') square_miles
--FROM   sample_polygons;

--===============================================================
-- ST_AsBinary(geometry)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT, wkb BLOB(32k)) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1100, ST_Point(10, 20, 1));

--INSERT INTO sample_points(id, wkb)
--VALUES (2222,
--  (SELECT  ST_AsBinary(geometry) 
--   FROM    sample_points
--   WHERE   id = 1100));

--SELECT id, cast(ST_AsText(ST_Point(wkb)) AS varchar(35)) AS point
--FROM   sample_points
--WHERE  id = 2222;

----This one is equal to the one above, but it uses method notation
--SELECT id, cast(ST_Point(wkb)..ST_AsText AS varchar(35)) AS point
--FROM   sample_points
--WHERE  id = 2222;

--SELECT id, substr(ST_AsBinary(geometry), 1, 21) AS point_wkb
--FROM   sample_points
--WHERE  id = 1100;

--===============================================================
-- ST_AsGML(geometry)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT, gml CLOB(32K)) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1100, ST_Point(10, 20, 1));

--INSERT INTO sample_points(id, gml)
--VALUES (2222,
--  (SELECT  ST_AsGML(geometry) 
--   FROM	   sample_points
--   WHERE   id = 1100));

--SELECT id, cast(ST_AsGML(geometry) AS varchar(110)) AS gml_fragment
--FROM   sample_points
--WHERE  id = 1100;

--===============================================================
-- ST_AsShape(geometry)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT, shape BLOB(32K)) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1100, ST_Point(10, 20, 1));

--INSERT INTO sample_points(id, shape)
--VALUES (2222,
--  (SELECT  ST_AsShape(geometry) 
--   FROM	   sample_points
--   WHERE   id = 1100));

--SELECT id, substr(ST_AsShape(geometry), 1, 20) AS shape
--FROM   sample_points
--WHERE  id = 1100;

--===============================================================
-- ST_AsText(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, spatial_type varchar(18), geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, spatial_type, geometry) 
--VALUES
--    (1, 'st_point', ST_Point(50, 50, 0) ),
--    (2, 'st_linestring', ST_LineString('linestring(200 100, 210 130, 220 140)',  0) ),
--    (3, 'st_polygon', ST_Polygon('polygon((110 120, 110 140, 130 140, 130 120, 110 120))', 0) );

--SELECT id, spatial_type, cast(geometry..ST_AsText AS varchar(150)) AS wkt
--FROM   sample_geometries;

--===============================================================
-- ST_Buffer(geometry, radius)
-- ST_Buffer(geometry, radius, unit)
--===============================================================
--!db2se drop_srs se_bank -srsName new_york1983;

--!db2se create_srs se_bank  -srsId 4000 -srsName new_york1983 -xOffset 0 -yOffset 0 -xScale 1 -yScale 1 -coordsysName NAD_1983_StatePlane_New_York_East_FIPS_3101_Feet;

--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id INTEGER, spatial_type varchar(18), geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, spatial_type, geometry)
--VALUES
--    (1, 'st_point', ST_Point(50, 50, 4000) ),
--    (2, 'st_linestring', ST_LineString('linestring(200 100, 210 130, 220 140)',  4000) ),
--    (3, 'st_polygon', ST_Polygon('polygon((110 120, 110 140, 130 140, 130 120, 110 120))', 4000) ),
--    (4, 'st_multipolygon', ST_MultiPolygon('multipolygon((
--                             (30 30, 30 40, 35 40, 35 30, 30 30),
--                             (35 30, 35 40, 45 40, 45 30, 35 30)))', 4000));

--SELECT id, spatial_type, 
--       cast(geometry..ST_Buffer(10)..ST_AsText AS varchar(470)) AS buffer_10
--FROM   sample_geometries;

--<TO DO> Defect -- SQL0440N  No authorized routine named "ST_NUMPOLYGONS" of type "FUNCTION" having compatible arguments was found.  SQLSTATE=42884
--SELECT id, spatial_type, 
--       cast(geometry..ST_Buffer(10)..ST_AsText AS varchar(470)) AS buffer,
--       ST_NumPolygons(ST_Buffer(geometry, 10))
--FROM   sample_geometries
--WHERE  id = 4;

--SELECT id, spatial_type, 
--       cast(ST_AsText(ST_Buffer(geometry, -5)) AS varchar(150)) AS buffer_negative_5
--FROM   sample_geometries
--WHERE  id = 3;

--SELECT id, spatial_type, 
--       cast(ST_AsText(ST_Buffer(geometry, 10, 'METER')) AS varchar(680)) AS buffer_10_meter
--FROM   sample_geometries
--WHERE  id = 3;


--===============================================================
-- ST_Contains(geometry, geometry)
--===============================================================
--DROP TABLE sample_points;
--DROP TABLE sample_lines;
--DROP TABLE sample_polygons;

--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;
--CREATE TABLE sample_lines(id SMALLINT, geometry ST_LINESTRING) organize by row;
--CREATE TABLE sample_polygons(id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_points (id, geometry) 
--VALUES
--    (1, ST_Point(10, 20, 1)),
--    (2, ST_Point('point(41 41)', 1));

--INSERT INTO sample_lines (id, geometry)
--VALUES
--    (10, ST_LineString('linestring (1 10, 3 12, 10 10)', 1) ),
--    (20, ST_LineString('linestring (50 10, 50 12, 45 10)', 1) );

--INSERT INTO sample_polygons(id, geometry) 
--VALUES
--      (100, ST_Polygon('polygon((0 0, 0 40, 40 40, 40 0, 0 0))',  1) );

--SELECT poly.id AS polygon_id,
--       CASE ST_Contains(poly.geometry, pts.geometry) 
--          WHEN 0 THEN 'does not contain'
--          WHEN 1 THEN 'does contain'
--       END AS contains,
--       pts.id AS point_id
--FROM   sample_points pts, sample_polygons poly;

--SELECT poly.id AS polygon_id,
--       CASE ST_Contains(poly.geometry, line.geometry) 
--          WHEN 0 THEN 'does not contain'
--          WHEN 1 THEN 'does contain'
--       END AS contains,
--       line.id AS line_id
--FROM   sample_lines line, sample_polygons poly;

--===============================================================
-- ST_ConvexHull(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, spatial_type varchar(18), geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, spatial_type, geometry) 
--VALUES
--    (1, 'ST_LineString', ST_LineString('linestring(20 20, 30 30, 20 40, 30 50)', 0) ),
--    (2, 'ST_Polygon', ST_Polygon('polygon((110  120,  110 140, 120 130, 110 120))', 0) ),
--    (3, 'ST_Polygon', ST_Polygon('polygon((30 30, 25 35, 15 50, 35 80, 40 85, 80 90, 70 75, 65 70, 55 50, 75 40, 60 30, 30 30))', 0) ),
--    (4, 'ST_MultiPoint', ST_MultiPoint('multipoint(20 20, 30 30, 20 40, 30 50)', 1) );

--SELECT id, spatial_type, cast(geometry..ST_ConvexHull..ST_AsText AS varchar(300)) AS convexhull
--FROM   sample_geometries;

--===============================================================
-- ST_Distance(geometry, geometry)
--===============================================================
--DROP TABLE sample_geometries1;
--DROP TABLE sample_geometries2;
--CREATE TABLE sample_geometries1 (id SMALLINT, spatial_type varchar(13), geometry ST_GEOMETRY) organize by row;
--CREATE TABLE sample_geometries2 (id SMALLINT, spatial_type varchar(13), geometry ST_GEOMETRY) organize by row;
rganize by row

--INSERT INTO sample_geometries1(id, spatial_type, geometry) 
--VALUES
--    ( 1, 'ST_Point', ST_Point('point(100 100)', 1) ),
--    (10, 'ST_LineString', ST_LineString('linestring(125 125, 125 175)', 1) ),
--    (20, 'ST_Polygon', ST_Polygon('polygon((50 50, 50 150, 150 150, 150 50, 50 50))', 1) );

--INSERT INTO sample_geometries2(id, spatial_type, geometry) 
--VALUES
--    (101, 'ST_Point', ST_Point('point(200 200)', 1) ),
--    (102, 'ST_Point', ST_Point('point(200 300)', 1) ),
--    (103, 'ST_Point', ST_Point('point(200 0)', 1) ),
--    (110, 'ST_LineString', ST_LineString('linestring(200 100, 200 200)', 1) ),
--    (120, 'ST_Polygon', ST_Polygon('polygon((200 0, 200 200, 300 200, 300 0, 200 0))', 1) );

--SELECT   sg1.id AS sg1_id, sg1.spatial_type AS sg1_type, 
--         sg2.id AS sg1_id, sg2.spatial_type AS sg2_type,
--         cast(ST_Distance(sg1.geometry, sg2.geometry) AS Decimal(8, 4)) AS distance
--FROM     sample_geometries1 sg1, sample_geometries2 sg2
--ORDER BY sg1.id;

--SELECT   sg1.id AS sg1_id, sg1.spatial_type AS sg1_type, 
--         sg2.id AS sg1_id, sg2.spatial_type AS sg2_type,
--         cast(ST_Distance(sg1.geometry, sg2.geometry) AS Decimal(8, 4)) AS distance
--FROM     sample_geometries1 sg1, sample_geometries2 sg2
--WHERE    ST_Distance(sg1.geometry, sg2.geometry)  <= 100;

--SELECT   sg1.id AS sg1_id, sg1.spatial_type AS sg1_type, 
--         sg2.id AS sg1_id, sg2.spatial_type AS sg2_type,
--         cast(ST_Distance(sg1.geometry, sg2.geometry, 'KILOMETER') AS DECIMAL(10, 4)) AS distance
--FROM     sample_geometries1 sg1, sample_geometries2 sg2
--ORDER BY sg1.id;

--===============================================================
-- St_FindMeasure(geometry, measure)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (1, ST_LineString('linestring m (2 2 3, 3 5 3, 3 3 6, 4 4 8)', 1)),
--    (2, ST_MultiPoint('multipoint m (2 2 3, 3 5 3, 3 3 6, 4 4 6, 5 5 6, 6 6 8)', 1));

--SELECT id, cast(ST_AsText(ST_FindMeasure(geometry, 7)) AS varchar(45)) AS measure_7
--FROM   sample_geometries;

-- Same as above, but with method notation
--SELECT id, cast(geometry..ST_FindMeasure(7)..ST_AsText AS varchar(45)) AS measure_7
--FROM   sample_geometries;

--SELECT id, cast(ST_AsText(ST_FindMeasure(geometry, 6)) AS varchar(120)) AS measure_6
--FROM   sample_geometries;

--SELECT id, cast(geometry..ST_FindMeasure(6)..ST_AsText AS varchar(120)) AS measure_6
--FROM   sample_geometries;

--===============================================================
-- ST_GeomCollection(LOB)
--===============================================================
--DROP TABLE sample_geomcollections;
--CREATE TABLE sample_geomcollections (id SMALLINT, geometry ST_GEOMCOLLECTION) organize by row;

--INSERT INTO sample_geomcollections(id, geometry) 
--VALUES
--    (4001, ST_GeomCollection('multipoint(1 2, 4 3, 5 6)', 1) ),
--    (4002, ST_GeomCollection('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) ),
--    (4003, ST_GeomCollection('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1)),
--    (4004, ST_GeomCollection('<gml:MultiPoint srsName="EPSG:4269"><gml:PointMember><gml:Point><gml:coord><gml:X>10</gml:X><gml:Y>20</gml:Y></gml:coord></gml:Point></gml:PointMember><gml:PointMember><gml:Point><gml:coord><gml:X>30</gml:X><gml:Y>40</gml:Y></gml:coord></gml:Point></gml:PointMember></gml:MultiPoint>', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(350)) AS geomcollection
--FROM   sample_geomcollections;

--===============================================================
-- ST_GeomCollFromTxt(WKT)
--===============================================================
--DROP TABLE sample_geomcollections;
--CREATE TABLE sample_geomcollections (id SMALLINT, geometry ST_GEOMCOLLECTION) organize by row;

--INSERT INTO sample_geomcollections(id, geometry) 
--VALUES
--    (4011, ST_GeomCollFromTxt('multipoint(1 2, 4 3, 5 6)', 1) ),
--    (4012, ST_GeomCollFromTxt('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) ),
--    (4013, ST_GeomCollFromTxt('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(340)) AS GeomCollection
--FROM   sample_geomcollections;

--===============================================================
-- ST_GeomCollFromWKB(WKB)
--===============================================================
--DROP TABLE sample_geomcollections;
--CREATE TABLE sample_geomcollections (id SMALLINT, geometry ST_GEOMCOLLECTION, wkb BLOB(32k)) organize by row;

--INSERT INTO sample_geomcollections(id, geometry) 
--VALUES
--    (4021, ST_GeomCollFromTxt('multipoint(1 2, 4 3, 5 6)', 1) ),
--    (4022, ST_GeomCollFromTxt('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12))', 1));

--UPDATE sample_geomcollections AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_GeomCollFromWKB(wkb)..ST_AsText AS varchar(190)) AS GeomCollection
--FROM   sample_geomcollections;

--===============================================================
-- ST_Geometry(LOB)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (7001, ST_Geometry('point(1 2)', 1) ),
--    (7002, ST_Geometry('linestring(33 2, 34 3, 35 6)', 1) ),
--    (7003, ST_Geometry('polygon((3 3, 4 6, 5 3, 3 3))', 1)),
--    (7004, ST_Geometry('<gml:Point srsName="EPSG:4269"><gml:coord><gml:X>50</gml:X><gml:Y>60</gml:Y></gml:coord></gml:Point>', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(120)) AS Geometry
--FROM   sample_geometries;

--===============================================================
-- ST_GeometryN(ST_GeomCollection)
--===============================================================
--DROP TABLE sample_geomcollections;
--CREATE TABLE sample_geomcollections (id SMALLINT, geometry ST_GEOMCOLLECTION) organize by row;

--INSERT INTO sample_geomcollections(id, geometry) 
--VALUES
--    (4001, ST_GeomCollection('multipoint(1 2, 4 3)', 1) ),
--    (4002, ST_GeomCollection('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) ),
--    (4003, ST_GeomCollection('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, cast(ST_GeometryN(geometry, 2)..ST_AsText AS varchar(110)) AS second_geometry
--FROM   sample_geomcollections;

--===============================================================
-- ST_GeometryType(ST_Geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (7101, ST_Geometry('point(1 2)', 1) ),
--    (7102, ST_Geometry('linestring(33 2, 34 3, 35 6)', 1) ),
--    (7103, ST_Geometry('polygon((3 3, 4 6, 5 3, 3 3))', 1)),
--    (7104, ST_Geometry('multipoint(1 2, 4 3)', 1) );

--SELECT id, geometry..ST_GeometryType AS geometry_type
--FROM   sample_geometries;

--===============================================================
-- ST_GeomFromTxt(WKT)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (1251, ST_GeomFromText('point(1 2)', 1) ),
--    (1252, ST_GeomFromText('linestring(33 2, 34 3, 35 6)', 1) ),
--    (1253, ST_GeomFromText('polygon((3 3, 4 6, 5 3, 3 3))', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(105)) AS Geometry
--FROM   sample_geometries;

--===============================================================
-- ST_GeomFromWKB(WKB)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries (id SMALLINT, geometry ST_GEOMETRY, wkb BLOB(32K)) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (1901, ST_GeomFromText('point(1 2)', 1) ),
--    (1902, ST_GeomFromText('linestring(33 2, 34 3, 35 6)', 1) ),
--    (1903, ST_GeomFromText('polygon((3 3, 4 6, 5 3, 3 3))', 1));

--UPDATE sample_geometries AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_GeomFromWKB(wkb)..ST_AsText AS varchar(190)) AS Geometry
--FROM   sample_geometries;

--===============================================================
-- ST_Intersects(geometry, geometry)
--===============================================================
--DROP TABLE sample_geometries1;
--DROP TABLE sample_geometries2;
--CREATE TABLE sample_geometries1 (id SMALLINT, spatial_type varchar(13), geometry ST_GEOMETRY) organize by row;
--CREATE TABLE sample_geometries2 (id SMALLINT, spatial_type varchar(13), geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries1(id, spatial_type, geometry) 
--VALUES
--    ( 1, 'ST_Point', ST_Point('point(550 150)', 1) ),
--    (10, 'ST_LineString', ST_LineString('linestring(800 800, 900 800)', 1) ),
--    (20, 'ST_Polygon', ST_Polygon('polygon((500 100, 500 200, 700 200, 700 100, 500 100))', 1) );

--INSERT INTO sample_geometries2(id, spatial_type, geometry) 
--VALUES
--    (101, 'ST_Point', ST_Point('point(550 150)', 1) ),
--    (102, 'ST_Point', ST_Point('point(650 200)', 1) ),
--    (103, 'ST_Point', ST_Point('point(800 800)', 1) ),
--    (110, 'ST_LineString', ST_LineString('linestring(850 250, 850 850)', 1) ),
--    (120, 'ST_Polygon', ST_Polygon('polygon((650 50, 650 150, 800 150, 800 50, 650 50))', 1) ),
--    (121, 'ST_Polygon', ST_Polygon('polygon((20 20, 20 40, 40 40, 40 20, 20 20))', 1) );

--SELECT   sg1.id AS sg1_id, sg1.spatial_type AS sg1_type, 
--         sg2.id AS sg1_id, sg2.spatial_type AS sg2_type,
--         CASE ST_Intersects(sg1.geometry, sg2.geometry)
--            WHEN 0 THEN 'Geometries do not intersect'
--            WHEN 1 THEN 'Geometries intersect'
--         END AS intersects
--FROM     sample_geometries1 sg1, sample_geometries2 sg2
--ORDER BY sg1.id;


--===============================================================
-- ST_Length(geometry)
--===============================================================
DROP TABLE sample_geometries;
CREATE TABLE sample_geometries(id SMALLINT, spatial_type varchar(20), geometry ST_GEOMETRY) organize by row;

INSERT INTO sample_geometries(id, spatial_type, geometry) 
VALUES
    (1110, 'ST_LineString', ST_LineString('linestring(50 10, 50 20)', 1) ),
    (1111, 'ST_MultiLineString', ST_MultiLineString('multilinestring(
                           (33 2, 34 3, 35 6),
                           (28 4, 29 5, 31 8, 43 12),
                           (39 3, 37 4, 36 7))', 1) );

SELECT id, spatial_type, cast(ST_Length(ST_ToLineString(geometry)) AS DECIMAL(7, 2)) AS line_length
FROM   sample_geometries
WHERE  id = 1110;

----Does the same as above, but in method notation
--SELECT id, spatial_type, cast(ST_Length(geometry..ST_ToLineString) AS DECIMAL(7, 2)) AS line_length
--FROM   sample_geometries
--WHERE  id = 1110;

----Currently this is failing with a GSE3016 defect
SELECT id, spatial_type, ST_Length(ST_ToMultiLine(geometry)) AS multiline_length
FROM   sample_geometries
WHERE  id = 1111;

----Does the same as above, but in method notation
--SELECT id, spatial_type, ST_Length(geometry..ST_ToMultiLine) AS multiline_length
--FROM   sample_geometries
--WHERE  id = 1111;

--===============================================================
-- ST_LineFromText(WKT)
--===============================================================
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines(id SMALLINT, geometry ST_LineString) organize by row;

--INSERT INTO sample_lines(id, geometry) 
--VALUES
--    (1110, ST_LineFromText('linestring(850 250, 850 850)', 1) ),
--    (1111, ST_LineFromText('linestring empty', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(75)) AS LineString
--FROM   sample_lines;

--===============================================================
-- ST_LineFromWKB(WKB)
--===============================================================
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines(id SMALLINT, geometry ST_LineString, wkb BLOB(32k)) organize by row;

--INSERT INTO sample_lines(id, geometry) 
--VALUES
--    (1901, ST_LineString('linestring(850 250, 850 850)', 1) ),
--    (1902, ST_LineString('linestring(33 2, 34 3, 35 6)', 1) );

--UPDATE sample_lines AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_LineFromWKB(wkb)..ST_AsText AS varchar(90)) AS Line
--FROM   sample_lines;

--===============================================================
-- ST_LineString(LOB)
--===============================================================
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines(id SMALLINT, geometry ST_LineString) organize by row;

--INSERT INTO sample_lines(id, geometry) 
--VALUES
--    (1110, ST_LineString('linestring(850 250, 850 850)', 1) ),
--    (1111, ST_LineString('<gml:LineString srsName="EPSG:4269"><gml:coord><gml:X>90</gml:X><gml:Y>90</gml:Y></gml:coord><gml:coord><gml:X>100</gml:X><gml:Y>100</gml:Y></gml:coord></gml:LineString>', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(75)) AS linestring
--FROM   sample_lines;

--===============================================================
-- ST_LineStringN(ST_MultiLineString)
--===============================================================
--DROP TABLE sample_mlines;
--CREATE TABLE sample_mlines (id SMALLINT, geometry ST_MULTILINESTRING) organize by row;

--INSERT INTO sample_mlines(id, geometry) 
--VALUES
--    (1110, ST_MultiLineString('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) ),
--    (1111, ST_MLineFromText('multilinestring(
--                           (61 2, 64 3, 65 6),
--                           (58 4, 59 5, 61 8),
--                           (69 3, 67 4, 66 7, 68 9))', 1) );

--SELECT id, cast(ST_LineStringN(geometry, 2)..ST_AsText AS varchar(110)) AS second_linestring
--FROM   sample_mlines;

--===============================================================
-- ST_M(st_point)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1, ST_Point(2, 3, 32, 5, 1)),
--    (2, ST_Point(4, 5, 20, 4, 1)),
--    (3, ST_Point(3, 8, 23, 7, 1));

--SELECT id, ST_M(geometry) AS measure
--FROM   sample_points;

----This does the same as above only in Method Notation
--SELECT id, geometry..ST_M AS measure
--FROM   sample_points;

--SELECT id, cast(ST_AsText(ST_M(geometry, 40)) AS varchar(60)) AS measure_40
--FROM   sample_points
--WHERE  id = 3;

--===============================================================
-- ST_MaxM(st_geometry)
-- ST_MaxX(st_geometry)
-- ST_MaxY(st_geometry)
-- ST_MaxZ(st_geometry)
-- ST_MinM(st_geometry)
-- ST_MinX(st_geometry)
-- ST_MinY(st_geometry)
-- ST_MinZ(st_geometry)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons(id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons(id, geometry) 
--VALUES
--    (1, ST_Polygon('polygon zm((110 120 20 3, 110 140 22 3, 120 130 26 4, 110 120 20 3))', 0) ),
--    (2, ST_Polygon('polygon zm((0 0 40 7, 0 4 35 9, 5 4 32 12, 5 0 31 5, 0 0 40 7))', 0) ),
--    (3, ST_Polygon('polygon zm((12 13 10 16 , 8 4 10 12, 9 4 12 11, 12 13 10 16))', 0) );

-----------------------------------------------------------------
-- ST_MaxM(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MaxM() AS SMALLINT) AS max_measure_per_polygon
--FROM   sample_polygons;

--< TO DO >--
--How do you include the id without the SQL failing
--SELECT cast(MAX(geometry..ST_MaxM()) AS SMALLINT) AS max_measure
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MaxX(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MaxX() AS SMALLINT) AS max_x_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MAX(geometry..ST_MaxX()) AS SMALLINT) AS max_x_coordinate
--FROM   sample_polygons;

--Super Min/Max Example
--SELECT cast(MIN(ST_MinX(geometry)) AS SMALLINT) AS MinX,
--       cast(MIN(ST_MinY(geometry)) AS SMALLINT) AS MinY,
--       cast(MIN(ST_MinZ(geometry)) AS SMALLINT) AS MinZ,
--       cast(MIN(ST_MinM(geometry)) AS SMALLINT) AS MinM,
--       cast(MAX(ST_MaxX(geometry)) AS SMALLINT) AS MaxX,
--       cast(MAX(ST_MaxY(geometry)) AS SMALLINT) AS MaxY,
--       cast(MAX(ST_MaxZ(geometry)) AS SMALLINT) AS MaxZ,
--       cast(MAX(ST_MaxM(geometry)) AS SMALLINT) AS MaxM
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MaxY(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MaxY() AS SMALLINT) AS max_y_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MAX(geometry..ST_MaxY()) AS SMALLINT) AS max_y_coordinate
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MaxZ(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MaxZ() AS SMALLINT) AS max_z_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MAX(geometry..ST_MaxZ()) AS SMALLINT) AS max_z_coordinate
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MinM(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MinM() AS SMALLINT) AS min_m_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MIN(geometry..ST_MinM()) AS SMALLINT) AS min_m_coordinate
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MinX(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MinX() AS SMALLINT) AS min_x_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MIN(geometry..ST_MinX()) AS SMALLINT) AS min_x_coordinate
--FROM   sample_polygons;

-----------------------------------------------------------------
-- ST_MinY(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MinY() AS SMALLINT) AS min_y_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MIN(geometry..ST_MinY()) AS SMALLINT) AS min_y_coordinate
--FROM   sample_polygons;


-----------------------------------------------------------------
-- ST_MinZ(st_geometry)
-----------------------------------------------------------------
--SELECT id, cast(geometry..ST_MinZ() AS SMALLINT) AS min_z_coordinate_per_polygon
--FROM   sample_polygons;

--SELECT cast(MIN(geometry..ST_MinZ()) AS SMALLINT) AS min_z_coordinate
--FROM   sample_polygons;


--===============================================================
-- St_MBR(geometry)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons (id, geometry) 
--VALUES
--    (1, ST_Polygon('polygon((5 5, 7 7, 5 9, 7 9, 9 11, 13 9, 15 9, 13 7, 15 5, 9 6, 5 5))', 0) ),
--    (2, ST_Polygon('polygon((20 30, 25 35, 30 30, 20 30))', 0));

--SELECT id, cast(geometry..ST_MBR..ST_AsText AS varchar(150)) AS MBR
--FROM   sample_polygons;

--===============================================================
-- St_MBRIntersect(geometry)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons (id, geometry) 
--VALUES
--    (1, ST_Polygon('polygon((0 0, 30 0, 40 30, 40 35, 5 35, 5 10, 20 10, 20 5, 0 0))', 0) ),
--    (2, ST_Polygon('polygon((15 15, 15 20, 60 20, 60 15, 15 15))', 0) ),
--    (3, ST_Polygon('polygon((115 15, 115 20, 160 20, 160 15, 115 15))', 0) );

--SELECT sp1.id, sp2.id,
--       CASE ST_MBRIntersects(sp1.geometry, sp2.geometry)
--          WHEN 0 THEN 'MBRs do not intersect'
--          WHEN 1 THEN 'MBRs intersect'
--       END AS mbr_intersects
--FROM   sample_polygons sp1, sample_polygons sp2
--WHERE  sp1.id <= sp2.id;

--===============================================================
-- St_MeasureBetween(geometry, startMeasure, endMeasure)
--===============================================================
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines (id SMALLINT, geometry ST_LINESTRING) organize by row;

--INSERT INTO sample_lines(id, geometry) 
--VALUES
--    (1, ST_LineString('linestring m (2 2 3, 3 5 3, 3 3 6, 4 4 6, 5 5 6, 6 6 8)', 1));

--SELECT id, cast(geometry..ST_MeasureBetween(4, 6)..ST_AsText AS varchar(150)) AS measure_between_4_and_6
--FROM   sample_lines;

--===============================================================
-- St_MidPoint(st_linestring)
--===============================================================
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines (id SMALLINT, geometry ST_LINESTRING) organize by row;

--INSERT INTO sample_lines(id, geometry) 
--VALUES
--    (1, ST_LineString('linestring (0 0, 0 10, 0 20, 0 30, 0 40)', 1)), 
--    (2, ST_LineString('linestring (2 2, 3 5, 3 3, 4 4, 5 5, 6 6)', 1)),
--    (3, ST_LineString('linestring (0 10, 0 0, 10 0, 10 10)', 1)), 
--    (4, ST_LineString('linestring (0 20, 5 20, 10 20, 15 20)', 1));

--SELECT id, cast(ST_AsText(ST_MidPoint(geometry)) AS varchar(60)) AS mid_point
--FROM   sample_lines;

---- Does the same as above but in method notation
--SELECT id, cast(geometry..ST_MidPoint..ST_AsText AS varchar(60)) AS mid_point
--FROM   sample_lines;

--===============================================================
-- St_MLineFromText(WKT)
--===============================================================
--DROP TABLE sample_mlines;
--CREATE TABLE sample_mlines (id SMALLINT, geometry ST_MULTILINESTRING) organize by row;

--INSERT INTO sample_mlines(id, geometry) 
--VALUES
--    (1110, ST_MLineFromText('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(280)) AS multilinestring
--FROM   sample_mlines
--WHERE  id = 1110;

--===============================================================
-- ST_MLineFromWKB(WKB)
--===============================================================
--DROP TABLE sample_mlines;
--CREATE TABLE sample_mlines (id SMALLINT, geometry ST_MULTILINESTRING, wkb BLOB(32K)) organize by row;

--INSERT INTO sample_mlines(id, geometry) 
--VALUES
--    (10, ST_MLineFromText('multilinestring(
--                           (61 2, 64 3, 65 6),
--                           (58 4, 59 5, 61 8),
--                           (69 3, 67 4, 66 7, 68 9))', 1) );

--UPDATE sample_mlines AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_MLineFromWKB(wkb)..ST_AsText AS varchar(280)) AS MultiLineString
--FROM   sample_mlines
--WHERE  id = 10;

--===============================================================
-- ST_MPointFromText(WKT)
--===============================================================
--DROP TABLE sample_mpoints;
--CREATE TABLE sample_mpoints (id SMALLINT, geometry ST_MULTIPOINT) organize by row;

--INSERT INTO sample_mpoints(id, geometry) 
--VALUES
--    (1110, ST_MPointFromText('multipoint(1 2, 4 3, 5 6)', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(280)) AS MultiPoint
--FROM   sample_mpoints
--WHERE  id = 1110;


--===============================================================
-- ST_MPointFromWKB(WKB)
--===============================================================
--DROP TABLE sample_mpoints;
--CREATE TABLE sample_mpoints (id SMALLINT, geometry ST_MULTIPOINT, wkb BLOB(32K)) organize by row;

--INSERT INTO sample_mpoints(id, geometry) 
--VALUES
--    (10, ST_MPointFromText('multipoint(44 14, 35 16, 24 13)', 1));

--UPDATE sample_mpoints AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_MPointFromWKB(wkb)..ST_AsText AS varchar(100)) AS MultiPoint
--FROM   sample_mpoints
--WHERE  id = 10;

--===============================================================
-- ST_MPolyFromText(WKT)
--===============================================================
--DROP TABLE sample_mpolygons;
--CREATE TABLE sample_mpolygons (id SMALLINT, geometry ST_MULTIPOLYGON) organize by row;

--INSERT INTO sample_mpolygons(id, geometry) 
--VALUES
--    (1110, ST_MPolyFromText('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(350)) AS MultiPolygon
--FROM   sample_mpolygons
--WHERE  id = 1110;

--===============================================================
-- ST_MPolyFromWKB(WKB)
--===============================================================
--DROP TABLE sample_mpolygons;
--CREATE TABLE sample_mpolygons (id SMALLINT, geometry ST_MULTIPOLYGON, wkb BLOB(32K)) organize by row;

--INSERT INTO sample_mpolygons(id, geometry) 
--VALUES
--    (10, ST_MPolyFromText('multipolygon(((1 72, 4 79, 5 76, 1 72),
--                              (10 20, 10 40, 30 41, 10 20),
--                              (9 43, 7 44, 6 47, 9 43)))', 1));

--UPDATE sample_mpolygons AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_MPolyFromWKB(wkb)..ST_AsText AS varchar(320)) AS MultiPolygon
--FROM   sample_mpolygons
--WHERE  id = 10;

--===============================================================
-- St_MultiLineString(LOB)
--===============================================================
--DROP TABLE sample_mlines;
--CREATE TABLE sample_mlines (id SMALLINT, geometry ST_MULTILINESTRING) organize by row;

--INSERT INTO sample_mlines(id, geometry) 
--VALUES
--    (1110, ST_MultiLineString('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(280)) AS MultiLineString
--FROM   sample_mlines
--WHERE  id = 1110;

--===============================================================
-- ST_MultiPoint(LOB)
--===============================================================
--DROP TABLE sample_mpoints;
--CREATE TABLE sample_mpoints (id SMALLINT, geometry ST_MULTIPOINT) organize by row;

--INSERT INTO sample_mpoints(id, geometry) 
--VALUES
--    (1110, ST_MultiPoint('multipoint(1 2, 4 3, 5 6)', 1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(90)) AS MultiPoint
--FROM   sample_mpoints
--WHERE  id = 1110;

--===============================================================
-- ST_MultiPolygon(LOB)
--===============================================================
--DROP TABLE sample_mpolygons;
--CREATE TABLE sample_mpolygons (id SMALLINT, geometry ST_MULTIPOLYGON) organize by row;

--INSERT INTO sample_mpolygons(id, geometry) 
--VALUES
--    (1110, ST_MultiPolygon('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(350)) AS MultiPolygon
--FROM   sample_mpolygons
--WHERE  id = 1110;

--===============================================================
-- ST_NumGeometries(collection)
--===============================================================
--DROP TABLE sample_geometrycol;
--CREATE TABLE sample_geometrycol(id SMALLINT, geometry ST_GEOMCOLLECTION) organize by row;

--INSERT INTO sample_geometrycol(id, geometry) 
--VALUES
--    (1, ST_MultiPolygon('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                                       (8 24, 9 25, 1 28, 8 24),
--                                       (13 33, 7 36, 1 40, 10 43, 13 33)))', 1)),
--    (2, ST_MultiPoint('multipoint(1 2, 4 3, 5 6, 7 6, 8 8)', 1) );

--SELECT id, ST_NumGeometries(geometry) AS number_of_geometries
--FROM   sample_geometrycol;

--===============================================================
-- ST_NumLineStrings(ST_MultiLineStrings)
--===============================================================
--DROP TABLE sample_mlines;
--CREATE TABLE sample_mlines (id SMALLINT, geometry ST_MULTILINESTRING) organize by row;

--INSERT INTO sample_mlines(id, geometry) 
--VALUES
--    (1110, ST_MultiLineString('multilinestring(
--                           (33 2, 34 3, 35 6),
--                           (28 4, 29 5, 31 8, 43 12),
--                           (39 3, 37 4, 36 7))', 1) ),
--    (1111, ST_MultiLineString('multilinestring(
--                           (3 2, 4 3, 5 6),
--                           (8 4, 9 5, 3 8, 4 12))', 1));

--SELECT id, ST_NumLineStrings(geometry) AS number_of_linestrings
--FROM   sample_mlines;

--===============================================================
-- ST_NumPoints(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(spatial_type varchar(18), geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(spatial_type, geometry) 
--VALUES
--    ('st_point', ST_Point(2, 3, 0) ),
--    ('st_linestring', ST_LineString('linestring(2 5, 21 3, 23 10)',  0) ),
--    ('st_polygon', ST_Polygon('polygon((110  120,  110 140, 120 130, 110 120))', 0) );

--SELECT spatial_type, geometry..ST_NumPoints AS number_of_points
--FROM   sample_geometries;

--===============================================================
-- ST_NumPolygons(multipolygon)
--===============================================================
--DROP TABLE sample_mpolygons;
--CREATE TABLE sample_mpolygons (id SMALLINT, geometry ST_MULTIPOLYGON);

--INSERT INTO sample_mpolygons(id, geometry) 
--VALUES
--    (1, ST_MultiPolygon('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1)),
--    (2, ST_MultiPolygon('multipolygon empty', 1)),
--    (3, ST_MultiPolygon('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                                       (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, ST_NumPolygons(geometry) AS number_of_polygons
--FROM   sample_mpolygons;

--===============================================================
-- ST_Overlaps(geometry, geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (1, ST_Point(10, 20, 1)),
--    (2, ST_Point('point(41 41)', 1)), 
--    (10, ST_LineString('linestring (1 10, 3 12, 10 10)', 1) ),
--    (20, ST_LineString('linestring (50 10, 50 12, 45 10)', 1) ),
--    (30, ST_LineString('linestring (50 12, 50 10, 60 8)', 1) ),
--    (100, ST_Polygon('polygon((0 0, 0 40, 40 40, 40 0, 0 0))',  1) ),
--    (110, ST_Polygon('polygon((30 10, 30 30, 50 30, 50 10, 30 10))',  1) ),
--    (120, ST_Polygon('polygon((0 50, 0 60, 40 60, 40 60, 0 50))',  1) );


----Tests weather Points Overlaps----Tests weather Points Overlaps
--SELECT sg1.id, sg2.id,
--       CASE ST_Overlaps(sg1.geometry, sg2.geometry)
--          WHEN 0 THEN 'Points_do_not_Overlap'
--          WHEN 1 THEN 'Points_Overlap'
--       END AS Overlap
--FROM   sample_geometries sg1, sample_geometries sg2
--WHERE  sg1.id < 10 AND sg2.id < 10 AND sg1.id >= sg2.id;

----Tests weather Lines Overlaps
--SELECT sg1.id, sg2.id,
--       CASE ST_Overlaps(sg1.geometry, sg2.geometry)
--          WHEN 0 THEN 'Lines_do_not_Overlap'
--          WHEN 1 THEN 'Lines_Overlap'
--       END AS Overlap
--FROM   sample_geometries sg1, sample_geometries sg2
--WHERE  sg1.id >= 10 AND sg1.id < 100 AND sg2.id >= 10 AND sg2.id < 100 
--       AND sg1.id >= sg2.id;

----Tests weather Polygons Overlaps
--SELECT sg1.id, sg2.id,
--       CASE ST_Overlaps(sg1.geometry, sg2.geometry)
--          WHEN 0 THEN 'Polygons_do_not_Overlap'
--          WHEN 1 THEN 'Polygons_Overlap'
--       END AS Overlap
--FROM   sample_geometries sg1, sample_geometries sg2
--WHERE  sg1.id >= 100 AND sg2.id >=100 
--       AND sg1.id >= sg2.id;

--===============================================================
-- ST_Perimeter(surface)
--===============================================================
--!db2se drop_srs se_bank -srsName new_york1983;

--!db2se create_srs se_bank  -srsId 4000 -srsName new_york1983 -xOffset 0 -yOffset 0 -xScale 1 -yScale 1 -coordsysName NAD_1983_StatePlane_New_York_East_FIPS_3101_Feet;

--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons(id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons(id, geometry)
--VALUES
--    (1, ST_Polygon('polygon((0  0,  0 4, 5 4, 5 0, 0 0))', 4000));

--SELECT id, ST_Perimeter(geometry) AS perimeter
--FROM   sample_polygons;

---- Does the samething as above but uses method notation
--SELECT id, geometry..ST_Perimeter AS perimeter
--FROM   sample_polygons;

--SELECT id, ST_Perimeter(geometry, 'METER') AS perimeter_meter
--FROM   sample_polygons;

--===============================================================
-- ST_PerpPoint(curve, point)
--===============================================================
--This is not updated with Bill's fixes
--DROP TABLE sample_lines;
--CREATE TABLE sample_lines(id SMALLINT, line ST_LINESTRING) organize by row;

--INSERT INTO sample_lines(id, line)
--VALUES
--    (1, ST_LineString('linestring z (0 10 1, 0 0 3, 10 0 5, 10 10 7)', 0) );

-- Perpendicular point is coincident with the input point, on the base of the U:
--SELECT ST_PerpPoint(line, ST_Point(5, 0, 0)) AS Perp_Point
--FROM   sample_lines;


--===============================================================
-- ST_Point(LOB)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1100, ST_Point(10, 20, 1)),
--    (1101, ST_Point('point(30 40)', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(35)) AS Points
--FROM   SAMPLE_POINTS;

--===============================================================
-- ST_PointFromText(WKT)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1100, ST_PointFromText('point(30 40)', 1));

--SELECT id, cast(geometry..ST_AsText AS varchar(35)) AS points
--FROM   sample_points;

--===============================================================
-- ST_PointFromWKB(WKB)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT, wkb BLOB(32k)) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (10, ST_PointFromText('point(44 14)', 1)),
--    (11, ST_PointFromText('point(24 13)', 1));

--UPDATE sample_points AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(geometry..ST_AsText AS varchar(35)) AS points
--FROM   SAMPLE_POINTS;

--===============================================================
-- ST_PolyFromText(WKT)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons(id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons(id, geometry)
--VALUES
--    (1110, ST_Polygon('polygon((50 20, 50 40, 70 30, 50 20))', 0) );

--SELECT id, cast(geometry..ST_AsText AS varchar(120)) AS polygons
--FROM   sample_polygons;

--===============================================================
-- ST_PolyFromWKB(WKB)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON, wkb BLOB(32K)) organize by row;

--INSERT INTO sample_polygons(id, geometry) 
--VALUES
--    (1115, ST_Polygon('polygon((50 20, 50 40, 70 30, 50 20))', 0) );

--UPDATE sample_polygons AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_PolyFromWKB(wkb)..ST_AsText AS varchar(120)) AS Polygon
--FROM   sample_polygons
--WHERE  id = 1115;

--===============================================================
-- ST_Polgyon(LOB)
--===============================================================
--DROP TABLE sample_polygons;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_polygons(id, geometry) 
--VALUES
--      (1100, ST_Polygon(db2gse.ST_LineFromText('linestring(10  20,  10 40, 20 30, 10 20)',  1), 1)),
--      (1101, ST_Polygon('polygon((110  120,  110 140, 120 130, 110 120))',  1) ),
--      (1102, ST_Polygon('polygon((110  120,  110 140, 130 140, 130 120, 110 120),(115 125, 115 135, 125 135, 125 135, 115 125))',  1) );

--SELECT id, cast(geometry..ST_AsText AS varchar(280)) AS Polygon
--FROM   sample_polygons;

--===============================================================
-- ST_PolgyonN(geometry)
--===============================================================
--DROP TABLE sample_mpolygons;
--CREATE TABLE sample_mpolygons (id SMALLINT, geometry ST_MULTIPOLYGON) organize by row;

--INSERT INTO sample_mpolygons(id, geometry) 
--VALUES
--    (1, ST_MPolyFromText('multipolygon(((3 3, 4 6, 5 3, 3 3),
--                              (8 24, 9 25, 1 28, 8 24),
--                              (13 33, 7 36, 1 40, 10 43, 13 33)))', 1));

--SELECT id, cast(geometry..ST_PolygonN(2)..ST_AsText AS varchar(120)) AS polygon_n
--FROM   sample_mpolygons
--WHERE  id = 1;

--===============================================================
-- ST_ToGeomColl(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (1, ST_Polygon('polygon((3 3, 4 6, 5 3, 3 3))', 1)),
--    (2, ST_Point('point(1 2)', 1) );

--SELECT id, cast(geometry..ST_ToGeomColl..ST_AsText AS varchar(120)) AS geometry_collections
--FROM   sample_geometries;

--===============================================================
-- ST_ToPoint(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry)
--VALUES
--    (1, ST_Geometry('point(30 40)', 1)),
--    (2, ST_Geometry('linestring empty', 1)),
--    (3, ST_Geometry('multipolygon empty', 1));

--SELECT cast(geometry..st_astext AS varchar(35)) AS points
--FROM   sample_geometries;

--SELECT cast(geometry..ST_ToPoint()..st_AsText() as varchar(35)) AS points
--FROM   sample_geometries;

--SELECT cast(TREAT(geometry AS ST_Point)..ST_AsText() as varchar(35)) AS points
--FROM   sample_geometries;

--===============================================================
-- ST_ToLineString(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry)
--VALUES
--    (1, ST_Geometry('linestring z (0 10 1, 0 0 3, 10 0 5)', 0)),
--    (2, ST_Geometry('point empty', 1)),
--    (3, ST_Geometry('multipolygon empty', 1));


--SELECT cast(geometry..ST_ToLineString()..st_AsText() as varchar(130)) AS lines
--FROM   sample_geometries;

--===============================================================
-- ST_ToPolygon(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry)
--VALUES
--    (1, ST_Geometry('polygon((0  0,  0 4, 5 4, 5 0, 0 0))', 1)), 
--    (2, ST_Geometry('point empty', 1)),
--    (3, ST_Geometry('multipolygon empty', 1));

--SELECT cast(geometry..ST_ToPolygon()..st_AsText() as varchar(130)) AS polygons
--FROM   sample_geometries;

--===============================================================
-- ST_ToMultiPoint(geometry)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry)
--VALUES
--    (1, ST_Geometry('multipoint(0  0,  0 4)', 1));
--    (2, ST_Geometry('point(30 40)', 1)),
--    (3, ST_Geometry('multipolygon empty', 1));

--SELECT cast(geometry..ST_ToMultiPoint()..st_AsText() as varchar(100)) AS MultiPoint
--FROM   sample_geometries;

--===============================================================
-- ST_Within(geometry)
--===============================================================
--DROP TABLE sample_points;
--DROP TABLE sample_lines;
--DROP TABLE sample_polygons;

--CREATE TABLE sample_points (id SMALLINT, geometry ST_POINT) organize by row;
--CREATE TABLE sample_lines(id SMALLINT, line ST_LINESTRING) organize by row;
--CREATE TABLE sample_polygons (id SMALLINT, geometry ST_POLYGON) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1, ST_Point(10, 20, 1)),
--    (2, ST_Point('point(41 41)', 1));
----    (2, ST_Point('point(50 50)', 1));  --Points to test defect

--INSERT INTO sample_lines(id, line)
--VALUES
--    (10, ST_LineString('linestring (1 10, 3 12, 10 10)', 1) ),
--    (20, ST_LineString('linestring (50 10, 50 12, 45 10)', 1) );

--INSERT INTO sample_polygons(id, geometry) 
--VALUES
--      (100, ST_Polygon('polygon((0 0, 0 40, 40 40, 40 0, 0 0))',  1) );

--SELECT pts.id AS point_ids_within_polygon
--FROM   sample_points pts, sample_polygons poly
--WHERE  ST_Within(poly.geometry, pts.geometry) = 0;

--SELECT lin.id AS line_ids_within_polygon
--FROM   sample_lines lin, sample_polygons poly
--WHERE  ST_Within(poly.geometry, lin.geometry) = 0;

--===============================================================
-- ST_WKBToSQL(wkb)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY, wkb BLOB(32k)) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (10, ST_Point('point(44 14)', 0)),
--    (11, ST_Point('point(24 13)', 0)),
--    (12, ST_Polygon('polygon((50 20, 50 40, 70 30, 50 20))', 0) );

--UPDATE sample_geometries AS temp_correlated
--SET    wkb = geometry..ST_AsBinary
--WHERE  id = temp_correlated.id;

--SELECT id, cast(ST_WKBToSQL(wkb)..ST_AsText AS varchar(120)) AS Geometries
--FROM   sample_geometries;

--===============================================================
-- ST_WKTToSQL(wkt)
--===============================================================
--DROP TABLE sample_geometries;
--CREATE TABLE sample_geometries(id SMALLINT, geometry ST_GEOMETRY) organize by row;

--INSERT INTO sample_geometries(id, geometry) 
--VALUES
--    (10, ST_WKTToSQL('point(44 14)')),
--    (11, ST_WKTToSQL('point(24 13)')),
--    (12, ST_WKTToSQL('polygon((50 20, 50 40, 70 30, 50 20))'));

--SELECT id, cast(geometry..ST_AsText AS varchar(120)) AS Geometries
--FROM   sample_geometries;

--===============================================================
-- ST_X(st_point)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1, ST_Point(2, 3, 32, 5, 1)),
--    (2, ST_Point(4, 5, 20, 4, 1)),
--    (3, ST_Point(3, 8, 23, 7, 1));

--SELECT id, geometry..ST_X AS x_coordinate
--FROM   sample_points;

--SELECT id, cast(ST_AsText(ST_X(geometry, 40)) AS varchar(60)) AS x_40
--FROM   sample_points
--WHERE  id = 3;

--===============================================================
-- ST_Y(st_point)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points (id, geometry) 
--VALUES
--    (1, ST_Point(2, 3, 32, 5, 1)),
--    (2, ST_Point(4, 5, 20, 4, 1)),
--    (3, ST_Point(3, 8, 23, 7, 1));

--SELECT id, geometry..ST_Y AS y_coordinate
--FROM   sample_points;

--SELECT id, cast(ST_AsText(ST_Y(geometry, 40)) AS varchar(60)) AS y_40
--FROM   sample_points
--WHERE  id = 3;

--===============================================================
-- ST_Z(st_point)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO SAMPLE_POINTS (id, geometry) 
--VALUES
--    (1, ST_Point(2, 3, 32, 5, 1)),
--    (2, ST_Point(4, 5, 20, 4, 1)),
--    (3, ST_Point(3, 8, 23, 7, 1));

--SELECT id, geometry..ST_Z AS z_coordinate
--FROM   sample_points;

--SELECT id, cast(ST_AsText(ST_Z(geometry, 40)) AS varchar(60)) AS z_40
--FROM   sample_points
--WHERE  id = 3;

--===============================================================
-- ST_GetAggrResult(MAX(ST_BuildUnionAggr(geometry)
--===============================================================
--DROP TABLE sample_points;
--CREATE TABLE sample_points(id SMALLINT, geometry ST_POINT) organize by row;

--INSERT INTO sample_points(id, geometry) 
--VALUES
--    (1, ST_Point(2,   3, 1)),
--    (2, ST_Point(4,   5, 1)),
--    (3, ST_Point(13, 15, 1)),
--    (4, ST_Point(12,  5, 1)),
--    (5, ST_Point(23,  2, 1)),
--    (6, ST_Point(11,  4, 1));

--SELECT cast(ST_GetAggrResult(MAX(ST_BuildUnionAggr(geometry)))..ST_AsText AS varchar(160)) AS aggregate_of_points
--FROM sample_points;

--SELECT cast(ST_GetAggrResult(MAX(ST_BuildUnionAggr(geometry)))..ST_ConvexHull..ST_AsText AS varchar(110)) AS aggregate_of_points
--FROM sample_points;



