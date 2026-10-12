/*
Goal: Identify return performance by reason, segmented by a small artificial grouping (A/B), and categorize total return amount as High or Low. The query combines two different filters on return amount and return quantity using UNION (distinct), includes a CASE expression, a scalar subquery for overall average return amount, and a CROSS JOIN with a tiny dimension table.
*/
WITH dim AS (
    SELECT 'A' AS grp
    UNION ALL
    SELECT 'B' AS grp
)
SELECT
    d.grp,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_amt,
    CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    (SELECT AVG(s2.sr_return_amt) FROM store_returns s2) AS avg_return_amt
FROM dim d
CROSS JOIN reason r
JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_amt > 100
GROUP BY d.grp, r.r_reason_desc

UNION

SELECT
    d.grp,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_amt,
    CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    (SELECT AVG(s2.sr_return_amt) FROM store_returns s2) AS avg_return_amt
FROM dim d
CROSS JOIN reason r
JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_quantity <= 30
GROUP BY d.grp, r.r_reason_desc

ORDER BY total_amt DESC, amount_category
LIMIT 100
