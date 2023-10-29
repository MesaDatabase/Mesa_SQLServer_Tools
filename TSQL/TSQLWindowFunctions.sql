--ranking functions

--rank by AnnualSales
SELECT
  SalesGroup,
  Country,
  AnnualSales,
  ROW_NUMBER() OVER(ORDER BY AnnualSales DESC) AS RowNumber,
  RANK() OVER(ORDER BY AnnualSales DESC) AS BasicRank,
  DENSE_RANK() OVER(ORDER BY AnnualSales DESC) AS DenseRank,
  NTILE(3) OVER(ORDER BY AnnualSales DESC) AS NTileRank
--select *
FROM RegionalSales;

--rank by AnnualSales within the partitions of SalesGroup
SELECT
  SalesGroup,
  Country,
  AnnualSales,
  ROW_NUMBER() OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS RowNumber,
  RANK() OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS BasicRank,
  DENSE_RANK() OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS DenseRank,
  NTILE(3) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS NTileRank
FROM RegionalSales;


--aggregate functions
--aggregate AnnualSales by SalesGroup
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  COUNT(AnnualSales) OVER(PARTITION BY SalesGroup) AS CountryCount,
  SUM(AnnualSales) OVER(PARTITION BY SalesGroup) AS TotalSales,
  AVG(AnnualSales) OVER(PARTITION BY SalesGroup) AS AverageSales
FROM RegionalSales
ORDER BY SalesGroup, AnnualSales DESC;

--aggregate AnnualSales by SalesGroup eliminating duplicate SalesGroup values
SELECT DISTINCT
  SalesGroup,
  COUNT(AnnualSales) OVER(PARTITION BY SalesGroup) AS CountryCount,
  SUM(AnnualSales) OVER(PARTITION BY SalesGroup) AS TotalSales,
  AVG(AnnualSales) OVER(PARTITION BY SalesGroup) AS AverageSales
FROM RegionalSales
ORDER BY TotalSales DESC;

--aggregate AnnualSales by SalesGroup with moving averages and cumulative data
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  COUNT(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS CountryCount,
  SUM(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS TotalSales,
  AVG(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS AverageSales
FROM RegionalSales;


--aggregate AnnualSales by SalesGroup with moving averages and cumulative data only calculating for the 2 preceeding rows
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  COUNT(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC ROWS 2 PRECEDING) AS CountryCount,
  SUM(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC ROWS 2 PRECEDING) AS TotalSales,
  AVG(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC ROWS 2 PRECEDING) AS AverageSales
FROM
  RegionalSales;


--analytic functions
--first_value and last_value
--first/last functions are highest/lowest AnnualSales values by SalesGroup, running total (highest sales for a row is the highest value encountered for the SalesGroup so far
--because of the order by clause
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  FIRST_VALUE(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS HighestSales,
  LAST_VALUE(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS LowestSales
FROM  RegionalSales;

--first/last functions are highest/lowest AnnualSales values by SalesGroup, uses all values in the calculation
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  FIRST_VALUE(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS HighestSales,
  LAST_VALUE(AnnualSales) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LowestSales
FROM RegionalSales;


--lag and lead
--lag and lead AnnualSales for SalesGroup ordering by AnnualSales
SELECT 
  SalesGroup,
  Country,
  AnnualSales,
  LAG(AnnualSales, 1) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS PreviousSale,
  LEAD(AnnualSales, 1) OVER(PARTITION BY SalesGroup ORDER BY AnnualSales DESC) AS NextSale
FROM RegionalSales;
