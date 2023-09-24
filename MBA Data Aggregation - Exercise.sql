
/*Q1: Create a flat file which contains all recipient data for each recipient and related claims data, 
as well as, the age of recipient on the date of service (DOS),  age group on DOS (<18 years = 1; 18 through 64 = 2; 65 and over = 3), 
and the short description of the claim type*/
IF OBJECT_ID('tempdb..#CombinedData') IS NOT NULL
    DROP TABLE #CombinedData;
SELECT 
    R.[Recipient ID],
	R.[ID2],
	C.[Claim Type],
    C.[Date of Service],
    C.[Proc Code],
    C.[Charged Amount],
    Ref.[Description],
    DATEDIFF(YEAR, R.[Date of Birth], C.[Date of Service]) AS [Age on DOS],
    CASE 
        WHEN DATEDIFF(YEAR, R.[Date of Birth], C.[Date of Service]) < 18 THEN 1
        WHEN DATEDIFF(YEAR, R.[Date of Birth], C.[Date of Service]) BETWEEN 18 AND 64 THEN 2
        ELSE 3
    END AS [Age Group on DOS]
INTO #CombinedData
FROM 
    Recipient AS R
JOIN 
    Claim AS C ON R.[Recipient ID] = C.[ID]
JOIN 
    Reference AS Ref ON C.[Claim Type] = Ref.[Claim Type]
ORDER BY 1;

--Q2:Create a summary table  of the total charge amount by age group and claim type.
SELECT
    [Age Group on DOS] AS Age_Group,
    [Claim Type] AS Claim_Type,
    SUM([Charged Amount]) AS Total_Charge_Amount
FROM #CombinedData
GROUP BY [Age Group on DOS], [Claim Type]
ORDER BY [Age Group on DOS], [Claim Type];

--Q3-1:Find the top 10 recipients with the highest total charges 
SELECT TOP 10
    [Recipient ID],
    SUM([Charged Amount]) AS Highest_Total_Charges
FROM #CombinedData
GROUP BY [Recipient ID]
ORDER BY 2 DESC;

--Q3-2:Top 10 recipients who had the most procedures
SELECT TOP 10
        [Recipient ID],
        COUNT(*) AS ProcedureCount
FROM #CombinedData
GROUP BY [Recipient ID]
ORDER BY ProcedureCount DESC;

--Q3-3:All recipients who were on both top 10 lists
WITH TotalChargesRank AS (
    SELECT
        [Recipient ID],
        SUM([Charged Amount]) AS Total_Charges
    FROM #CombinedData
    GROUP BY [Recipient ID]
    ORDER BY Total_Charges DESC
    OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY
),
ProceduresRank AS (
    SELECT
        [Recipient ID],
        COUNT(*) AS ProcedureCount
    FROM #CombinedData 
    GROUP BY [Recipient ID]
    ORDER BY ProcedureCount DESC
    OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY
)
SELECT
    TC.[Recipient ID] AS RecipientWithHighestCharges,
    PR.[Recipient ID] AS RecipientWithMostProcedures
FROM TotalChargesRank TC
JOIN ProceduresRank PR ON TC.[Recipient ID] = PR.[Recipient ID];


--Q4:Find the recipient who at the least number of visits and the most number of visits
WITH VisitCounts AS (
    SELECT
        [Recipient ID],
        COUNT(DISTINCT[Date of Service]) AS VisitCount
    FROM
        #CombinedData
    GROUP BY
        [Recipient ID]
)
SELECT 
    CASE 
        WHEN V.VisitCount = MinVisits THEN 'Min'
        ELSE 'Max'
    END AS VisitType,
    V.[Recipient ID],
    V.VisitCount
FROM 
    VisitCounts V
JOIN 
    (SELECT MIN(VisitCount) AS MinVisits, MAX(VisitCount) AS MaxVisits FROM VisitCounts) AS MinMax
ON 
    V.VisitCount = MinMax.MinVisits OR V.VisitCount = MinMax.MaxVisits
ORDER BY
    V.VisitCount;
































