-- Query information about driver name, NRIC, travel time in each trip, number plate, SID for each bus in May, July, October, November 2020

SELECT d.Name as Driver_name
    , d.NRIC as NRIC
    , MONTH(TDate) as Month
    , DATEDIFF(MINUTE, b.StartTime, b.EndTime) as Transit_time
    , b.PlateNo
    , b.SID 
FROM bustrip b 
JOIN driver d ON b.DID = d.DID
WHERE MONTH(TDate) IN(5, 7, 10, 11) AND YEAR(TDate) = 2020
ORDER BY DATEDIFF(MINUTE, b.StartTime, b.EndTime)

-- Find all bus stops that contain 'bridge' or 'changi' in the address or description of the bus stop,the bus routes that pass through them, and other information in the following format:
-- Stopid, LocationDes, Address, SID , Type (Normal or Express), WeekdayFreq, WeekendFreq

SELECT s.StopID 
    , s.LocationDes
    , s.Address
    , sv.SID
    , CASE WHEN sv.Normal = 1  
        THEN 'Normal' 
            ELSE 'Express' 
                END as Type
    , n.WeekdayFreq
    , CASE WHEN n.WeekdayFreq > 12 THEN 'High' 
            WHEN n.WeekdayFreq BETWEEN 6 AND 12 THEN 'Medium'
                ELSE 'Low' 
                    END as Checking
FROM stop s 
LEFT JOIN stoprank sr ON s.StopID = sr.StopID
LEFT JOIN service sv ON sr.SID = sv.SID 
LEFT JOIN normal n ON sv.SID = n.SID
WHERE s.LocationDes LIKE '%bridge%' 
    OR s.LocationDes LIKE '%Bridge%' 
    OR s.Address LIKE '%Changi%'
    OR s.Address LIKE '%changi%'
ORDER BY s.stopID DESC
    , sv.SID DESC

-- For each bus card that is a substitute for another, query for the following information:
-- ReplacedCardID, Expiry, NumberOfRide, OldCardID, NumberOfRide_Old

-- a)
SELECT c.CardID as ReplacedCardID
    , c.Expiry
    , COUNT(r.CardID) as NumberOfRide
    , c.OldCardID
    , (SELECT COUNT(*) FROM ride WHERE c.OldCardID = ride.CardID) as NumberOfRide_Old
FROM citylink c 
LEFT JOIN ride r ON c.CardID = r.CardID
WHERE c.OldCardID IS NOT NULL 
GROUP BY c.CardID
    , c.Expiry
    , c.OldCardID
ORDER BY COUNT(r.CardID) 

-- b)
WITH pa AS
(
SELECT c.CardID as ReplacedCardID
    , c.Expiry
    , COUNT(r.CardID) as NumberOfRide
    , c.OldCardID
    , (SELECT COUNT(*) FROM ride WHERE c.OldCardID = ride.CardID) as NumberOfRide_Old
FROM citylink c 
LEFT JOIN ride r ON c.CardID = r.CardID
WHERE c.OldCardID IS NOT NULL 
GROUP BY c.CardID
    , c.Expiry
    , c.OldCardID 
)

SELECT COUNT(*) as Result_b
FROM pa
WHERE NumberOfRide > NumberOfRide_Old

-- c)
WITH pa AS
(
SELECT c.CardID as ReplacedCardID
    , c.Expiry
    , COUNT(r.CardID) as NumberOfRide
    , c.OldCardID
    , (SELECT COUNT(*) FROM ride WHERE c.OldCardID = ride.CardID) as NumberOfRide_Old
FROM citylink c 
LEFT JOIN ride r ON c.CardID = r.CardID
WHERE c.OldCardID IS NOT NULL 
GROUP BY c.CardID
    , c.Expiry
    , c.OldCardID 
)

SELECT COUNT(*) as Result_c
FROM pa
WHERE NumberOfRide_Old % 2 = 0

-- For each bus route, find the 4 bus stops with the highest traffic (calculated by boarding + alighting) in each year 2019, 2020, 2021, and return in the following format:
-- Year, Stop_id, Traffic_cnt, Rank

WITH boarded_cnt_by_sid_and_stopid AS
	(SELECT YEAR(ride.rdate) year
		, Boardstop as stop_id
		, Count(*) as traffic_cnt
	FROM ride
	WHERE YEAR(ride.rdate) IN(2019, 2020, 2021)
	GROUP BY YEAR(ride.rdate), SID, Boardstop)

, alighted_cnt_by_sid_and_stopid AS
	(SELECT YEAR(ride.rdate) year
		, Alightstop as stop_id
		, Count(*) as traffic_cnt
	FROM ride
	WHERE YEAR(ride.rdate) IN(2019, 2020, 2021)
	GROUP BY YEAR(ride.rdate), SID, Alightstop)

, union_cnt_by_sid_and_stopid AS
	(SELECT * FROM boarded_cnt_by_sid_and_stopid
	UNION ALL
	SELECT * FROM alighted_cnt_by_sid_and_stopid)

, traffic_by_sid_and_stopid AS
	(SELECT year
		, stop_id
		, SUM(traffic_cnt) as traffic_cnt
	FROM union_cnt_by_sid_and_stopid
	GROUP BY year, stop_id)

, traffic_by_sid_and_stopid_ranked AS
	(SELECT year
		, stop_id
		, traffic_cnt
		, ROW_NUMBER() OVER (
			PARTITION BY year
			ORDER BY traffic_cnt DESC) as rank
	FROM traffic_by_sid_and_stopid)

SELECT year
	, stop_id
	, traffic_cnt
	, rank
FROM traffic_by_sid_and_stopid_ranked
WHERE rank <= 4
ORDER BY year
    , rank
    , stop_id ASC
    , traffic_cnt ASC