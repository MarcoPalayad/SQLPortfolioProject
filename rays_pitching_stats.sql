SELECT *
FROM rays_pitching.dbo.last_pitch_rays;

SELECT *
FROM rays_pitching.dbo.rays_pitching_stats;


--Q.1a.AVG pitches per at bat 

SELECT AVG(1.00 * pitch_number) avgpitchesperatbat
FROM rays_pitching.dbo.last_pitch_rays

--Q.1b. AVG pitches per at bat home vs away


SELECT 
	'Home' Typeofgame,
	AVG(1.00 * pitch_number) avgpitchesperatbat
FROM rays_pitching.dbo.last_pitch_rays
WHERE home_team = 'TB'
UNION
SELECT 
	'Away' Typeofgame,
	AVG(1.00 * pitch_number) avgpitchesperatbat
FROM rays_pitching.dbo.last_pitch_rays
WHERE away_team = 'TB'


--Q.1c. AVG pitches per at bat lefty vs righty

SELECT
	AVG(CASE
			WHEN batter_position = 'L' 
			THEN 1.00 * pitch_number
			END
		) leftyatbat,
	AVG(CASE
			WHEN batter_position = 'R' 
			THEN 1.00 * pitch_number
			END
		) rightyatbat
FROM rays_pitching.dbo.last_pitch_rays
WHERE away_team = 'TB'


--Q.1d. AVG pithces per at bat | lefty vs righty pitcher | each away team

SELECT
	DISTINCT	
	home_team,
	pitcher_position,
	AVG( 1.00 * pitch_number ) OVER (PARTITION BY home_team, pitcher_position) avgpitchesperteam
FROM 
	rays_pitching.dbo.last_pitch_rays
WHERE
	away_team = 'TB'

--Q.1e. Top 3 Most Common pitch for at bat 1 through 10, and total amounts

WITH totalpitches as (

SELECT
	DISTINCT pitch_name,
	pitch_number,
	COUNT(pitch_name) OVER (PARTITION BY pitch_name, pitch_number) pitchfrequency
FROM
	rays_pitching.dbo.last_pitch_rays
WHERE
	pitch_number < 11
),
pitchfrqrankingquery AS (
SELECT 
	pitch_name,
	pitch_number,
	pitchfrequency,
	RANK() OVER (PARTITION BY pitch_number ORDER BY pitchfrequency DESC) pitchfreqranking
FROM 
	totalpitches
)

SELECT
	*
FROM
	pitchfrqrankingquery
WHERE 
	pitchfreqranking < 4


--Q.1f. AVG pitches	per at bat per pitcher with 20+ innings | order in descending (last_pitch_rays, rays_pitching_stats) 

SELECT
	rps.Name,
	AVG( 1.00 * pitch_number ) avgpitches
FROM
	last_pitch_rays lpr
JOIN 
	rays_pitching_stats rps ON rps.pitcher_id = lpr.pitcher
WHERE
	IP >= 20
GROUP BY
	rps.Name
ORDER BY
	AVG( 1.00 * pitch_number ) DESC


--Q.2a. count the last pitches thrown in desc order

SELECT
	pitch_name,
	COUNT(*) timesthrown
FROM
	last_pitch_rays
GROUP BY 
	pitch_name
ORDER BY
	COUNT(*) DESC


--Q.2b. count of the different last pitches fastball or offspeed 

SELECT
	SUM(CASE WHEN pitch_name IN ( '4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) fastball,	
	SUM(CASE WHEN pitch_name NOT IN ( '4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) offspeed
FROM
	last_pitch_rays


--Q.2c. percentage of the different last pitches fastball or offspeed

SELECT
	100* SUM(CASE WHEN pitch_name IN ( '4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) / COUNT(*) fastballpercent,	
	100* SUM(CASE WHEN pitch_name NOT IN ( '4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) / COUNT(*) offspeedpercent
FROM
	last_pitch_rays


--Q.2d. Top 5 most common last pitches for a relief pitcher vs starting pitcher

SELECT 
	*
FROM (
	SELECT
		a.pos,
		a.pitch_name,
		a. timesthrown,
		RANK () OVER (PARTITION BY a.pos ORDER BY a.timesthrown DESC) pitchrank
	FROM (SELECT
			rps.pos,
			lpr.pitch_name,
			COUNT(*) timesthrown
		  FROM
			last_pitch_rays lpr
		  JOIN 
			rays_pitching_stats rps ON rps.pitcher_id = lpr.pitcher
		  GROUP BY
			rps.pos,
			lpr.pitch_name
	) a
) b
WHERE 
	b.pitchrank < 6


--Q.3a. what pitches have given up most HRs (Homeruns)
-- doesnt work due to bad data
--SELECT *
--FROM rays_pitching.dbo.last_pitch_rays
--WHERE hit_location is NULL AND bb_type = 'fly_ball'

-- actual method
SELECT
	pitch_name,
	COUNT(*) HRs
FROM 
	rays_pitching.dbo.last_pitch_rays
WHERE 
	events = 'home_run'
GROUP BY
	pitch_name
ORDER BY
	COUNT(*) DESC 


--Q.3b. show HRs given up by zone and pitch , show top 5 most common

SELECT
	TOP 5 zone, pitch_name, COUNT(*) HRs
FROM 
	last_pitch_rays
WHERE 
	events = 'home_run'
GROUP BY 
	zone, 
	pitch_name
ORDER BY
	COUNT(*) DESC


--Q.3c. show HRs for each type --> balls/strikes + pitcher

SELECT
	rps.pos,
	lpr.balls,
	lpr.strikes,
	COUNT(*) HRs
FROM
	last_pitch_rays lpr
JOIN 
	rays_pitching_stats rps ON rps.pitcher_id = lpr.pitcher
WHERE 
	events = 'home_run'
GROUP BY 
	rps.pos,
	lpr.balls,
	lpr.strikes
ORDER BY
	COUNT(*) DESC


--Q.3d. show each pitcher most common count to give up HRs (min 30 tp)

WITH HRscountpitcher as (
SELECT
	rps.Name,
	lpr.balls,
	lpr.strikes,
	COUNT(*) HRs
FROM
	last_pitch_rays lpr
JOIN 
	rays_pitching_stats rps ON rps.pitcher_id = lpr.pitcher
WHERE 
	events = 'home_run' AND IP >= 30
GROUP BY 
	rps.Name,
	lpr.balls,
	lpr.strikes
),
HRscountrankings as (
	SELECT
		hcp.Name,
		hcp.balls,
		hcp.strikes, 
		hcp.HRs,
		RANK () OVER (PARTITION BY name ORDER BY HRs DESC) HRsRank
	FROM HRscountpitcher hcp
)
SELECT 
	ht.Name,
	ht.balls,
	ht.strikes, 
	ht.HRs
FROM HRscountrankings ht
WHERE HRsRank =1


--Q.4

--SELECT *
--FROM last_pitch_rays lpr
--JOIN rays_pitching_stats rps ON rps.pitcher_id = lpr.pitcher

--Q.4a. AVG speed, spinrate, strikeout, most popular zone

SELECT
	AVG(release_speed) avgrspeed,
	AVG(release_spin_rate) avgspnrt,
	SUM(CASE WHEN events ='strikeout' THEN 1 ELSE 0 END) strikeouts,
	MAX(zones.zone) as zone
FROM last_pitch_rays lpr
JOIN (
	SELECT 
		TOP 1 pitcher, zone, COUNT(*) zonenum
	FROM
		last_pitch_rays lpr
	WHERE 
		player_name = 'McClanahan, Shane'
	GROUP BY
		pitcher, zone 
	ORDER BY COUNT(*) DESC
) zones ON zones.pitcher = lpr.pitcher
WHERE player_name = 'McClanahan, Shane'


--Q.4b. top pitches for each infield position where total pitches are over 5, rank them

SELECT *
FROM (

SELECT pitch_name, COUNT(*) timeshit, 'Third' Position
FROM last_pitch_rays
WHERE hit_location = 5 AND player_name = 'McClanahan, Shane'
GROUP BY pitch_name
UNION
	SELECT pitch_name, COUNT(*) timeshit, 'Short' Position
	FROM last_pitch_rays
	WHERE hit_location = 6 AND player_name = 'McClanahan, Shane'
	GROUP BY pitch_name
UNION
	SELECT pitch_name, COUNT(*) timeshit, 'Second' Position
	FROM last_pitch_rays
	WHERE hit_location = 4 AND player_name = 'McClanahan, Shane'
	GROUP BY pitch_name
UNION
	SELECT pitch_name, COUNT(*) timeshit, 'First' Position
	FROM last_pitch_rays
	WHERE hit_location = 3 AND player_name = 'McClanahan, Shane'
	GROUP BY pitch_name
) a
WHERE timeshit > 4
ORDER BY timeshit DESC


--Q.4c. show different balls/strikes as well as frequency when someone is on base

SELECT
	balls,
	strikes,
	COUNT(*) frequency 
FROM 
	last_pitch_rays
WHERE
	(on_3b IS NOT NULL OR on_2b IS NOT NULL OR on_1b IS NOT NULL )
	AND player_name = 'McClanahan, Shane'
GROUP BY
	balls,
	strikes
ORDER BY
	COUNT(*) DESC


--Q.4d. what pitch causes the lowest launch speed

SELECT
	TOP 1 pitch_name,
	AVG(launch_speed * 1.00) launchspeed
FROM
	last_pitch_rays
WHERE
	player_name = 'McClanahan, Shane'
GROUP BY
	pitch_name
ORDER BY
	AVG(launch_speed)
