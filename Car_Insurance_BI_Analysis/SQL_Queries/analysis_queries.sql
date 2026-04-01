# Verify the Import (Check row counts)
SELECT COUNT(*) FROM policy_sales_data;
SELECT COUNT(*) FROM claims_data;

# Adding Indexes for Fast Queries
CREATE INDEX idx_vehicle_policy
ON policy_sales_data(Vehicle_ID);

CREATE INDEX idx_vehicle_claim
ON claims_data(Vehicle_ID);

CREATE INDEX idx_policy_dates 
ON policy_sales_data(Policy_Start_Date, Policy_End_Date);

# # Analytical Queries

# Query 1: Calculate the total premium collected during the year 2024.
-- Premium = Policy_Tenure * 100
SELECT 
SUM(Premium) AS Total_Premium_Collected
FROM policy_sales_data;

# Query 2: Calculate the total claim cost for each year (2025 and 2026) with a monthly breakdown.
SELECT 
YEAR(Claim_Date) AS Claim_Year,
MONTH(Claim_Date) AS Claim_Month,
SUM(Claim_Amount) AS Total_Claim_Cost
FROM claims_data
GROUP BY Claim_Year, Claim_Month
ORDER BY Claim_Year, Claim_Month;

-- Interpretation: This Shows Monthly Claim Pattern and Yearly Claim Cost

# Query 3: Calculate the claim cost to premium ratio for each policy tenure (1, 2, 3, and 4 years).
-- Claim Ratio = Claims / Premium
SELECT 
p.Policy_Tenure,
SUM(c.Claim_Amount) AS Total_Claims,
SUM(p.Premium) AS Total_Premium,
Round(SUM(c.Claim_Amount) / SUM(p.Premium),2) AS Claim_Premium_Ratio
FROM policy_sales_data p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
GROUP BY p.Policy_Tenure
ORDER BY p.Policy_Tenure;

-- Interpretation: This Identifies risk level Of each tenure. 

# Query 4: Calculate the claim cost to premium ratio by the month in which the policy was sold (January–December 2024).
SELECT 
MONTH(p.Policy_Purchase_Date) AS Sale_Month,
SUM(c.Claim_Amount) AS Total_Claims,
SUM(p.Premium) AS Total_Premium,
Round(SUM(c.Claim_Amount) / SUM(p.Premium),2) AS Claim_Premium_Ratio
FROM policy_sales_data p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
GROUP BY Sale_Month
ORDER BY Sale_Month;

-- Interpretation: This reveals seasonality in risk exposure.

# Query 5: If every vehicle that has not yet made a claim eventually files exactly one claim during the remaining policy tenure, estimate the total potential claim liability.
-- For total potential future claim liability
-- Logic: Vehicles without claim × claim amount
SELECT 
COUNT(p.Vehicle_ID) * 10000 AS Estimated_Future_Liability
FROM policy_sales_data p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
WHERE c.Vehicle_ID IS NULL;

-- Explanation: Vehicles that never claimed and Assume one claim each

# Query 6: Assume Daily Premium: Premium / (Policy_Tenure × 365)
-- part 1 - Calculate the premium already earned by the company up to February 28, 2026.
SELECT 
Round(SUM(
Premium /
(Policy_Tenure * 365) *
DATEDIFF(
LEAST(Policy_End_Date, '2026-02-28'),
Policy_Start_Date
)
), 2
) AS Earned_Premium
FROM policy_sales_data
WHERE Policy_Start_Date <= '2026-02-28';

-- Part 2: Estimate the premium expected to be earned monthly for the remaining policy period (assume 46 months remaining).
-- Monthly Premium Expected (Remaining 46 months)
SELECT
Round(SUM(Premium) / 46, 2) AS Expected_Monthly_Premium
FROM policy_sales_data;


# # Bonus Analysis

# Query 1: Identify which policy tenure appears most profitable and explain why.
-- Most Profitable Policy Tenure
SELECT 
p.Policy_Tenure,
SUM(p.Premium) AS Total_Premium,
SUM(c.Claim_Amount) AS Total_Claims,
Round(SUM(c.Claim_Amount)/SUM(p.Premium),3) AS Loss_Ratio
FROM policy_sales_data p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID
GROUP BY p.Policy_Tenure
ORDER BY Loss_Ratio;

-- Interpretation: Lower loss ratio = higher profitability

# Query 2: Claim trends by month.
SELECT 
DATE_FORMAT(Claim_Date,'%Y-%m') AS Claim_Month,
COUNT(*) AS Total_Claims,
SUM(Claim_Amount) AS Claim_Cost
FROM claims_data
GROUP BY Claim_Month
ORDER BY Claim_Month;

# Query 3: Estimate the loss ratio (Claims ÷ Premium) for the portfolio.
SELECT
Round(SUM(c.Claim_Amount) / SUM(p.Premium), 2) AS Portfolio_Loss_Ratio
FROM policy_sales_data p
LEFT JOIN claims_data c
ON p.Vehicle_ID = c.Vehicle_ID;

# Query 4: If claim frequency increases by 5% annually, estimate the impact on future profitability.
-- Impact of 5% Annual Claim Increase
-- Projected claims: Future Claims = Current Claims × 1.05
SELECT
SUM(Claim_Amount) * 1.05 AS Projected_Claims_Next_Year
FROM claims_data;

-- Interpretation: This shows future profitability risk. 
-- Profitability will decrease due to higher claim payouts.



