WITH sales_all AS (
    -- Combine catalog and web sales into a single fact set
    SELECT cs.cs_bill_customer_sk        AS cust_sk,
           cs.cs_bill_cdemo_sk          AS cdemo_sk,
           cs.cs_bill_hdemo_sk          AS hdemo_sk,
           cs.cs_net_paid               AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_bill_customer_sk,
           ws.ws_bill_cdemo_sk,
           ws.ws_bill_hdemo_sk,
           ws.ws_net_paid
    FROM web_sales ws
),

-- Small dimension (distinct genders) cross‑joined with a tiny derived set
DimCross AS (
    SELECT g.cd_gender,
           f.flag
    FROM (SELECT DISTINCT cd_gender FROM customer_demographics) g
    CROSS JOIN (SELECT 1 AS flag UNION ALL SELECT 2 AS flag) f
),

Agg AS (
    SELECT
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(s.net_paid)          AS total_net_paid,
        COUNT(*)                 AS txn_count
    FROM sales_all s
    JOIN customer_demographics cd
      ON s.cdemo_sk = cd.cd_demo_sk                      -- valid join rule
    JOIN household_demographics hd
      ON s.hdemo_sk = hd.hd_demo_sk                      -- valid join rule
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk    -- valid join rule
    JOIN DimCross dc
      ON cd.cd_gender = dc.cd_gender                    -- link to the cross‑joined dimension
    WHERE cd.cd_gender = 'F'                               -- predicate 1
      AND ib.ib_lower_bound >= 50000                       -- predicate 2
      AND s.net_paid > 0                                   -- predicate 3
    GROUP BY CUBE(cd.cd_gender, hd.hd_buy_potential)       -- all‑dimension combinations
    HAVING SUM(s.net_paid) > 1000                         -- filter after aggregation
)
SELECT
    cd_gender,
    hd_buy_potential,
    total_net_paid,
    txn_count,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank,
    (SELECT AVG(net_paid) FROM sales_all)        AS avg_net_paid_overall  -- scalar subquery
FROM Agg
ORDER BY total_net_paid DESC
LIMIT 100
