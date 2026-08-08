----------------
-- TIME TRAVEL
----------------
SELECT * FROM TESLA_STOCKS order by DATE desc;

-- dropping & getting back the table (time travel)
DROP TABLE TESLA_STOCKS;
UNDROP TABLE TESLA_STOCKS;

-- updating values
UPDATE TESLA_STOCKS SET OPEN_VALUE=200 WHERE DATE = '2022-08-01';

-- getting data beofre last upodate query
SELECT * FROM TESLA_STOCKS BEFORE (statement => '01bf337e-0000-3406-005a-1e0b0003fe22') ORDER BY DATE DESC;
