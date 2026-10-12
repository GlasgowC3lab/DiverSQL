/*
Goal: Analyze store return amounts and web sales profit broken down by year & state and by customer gender, applying realistic filters on year, time of day, store state, customer gender, sale quantity and return amount. The query demonstrates:
- joins across all eight selected tables using only the allowed join keys (left‑deep chain)
- at least five selective predicates with realistic literal values
- an IN filter with an uncorrelated subquery
- a CROSS JOIN with a small computed set
- aggregation using GROUPING SETS
- a LIMIT of 100 rows for preview
*/
WITH page_home AS (
    SELECT wp_web_page_sk
    FROM web_page
    WHERE wp_type = 'home'
)
SELECT
    d.d_year,
    s.s_state,
    cd.cd_gender,
    SUM(sr.sr_return_amt)                AS total_return_amt,
    AVG(ws.ws_net_profit)                AS avg_net_profit,
    COUNT(DISTINCT s.s_store_id)         AS cnt_stores
FROM store_returns sr
JOIN date_dim d        ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t        ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s           ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws      ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite    ON ws.ws_web_site_sk = wsite.web_site_sk
CROSS JOIN (VALUES (1), (2)) AS v(flag)
WHERE d.d_year               = 2001
  AND t.t_am_pm              = 'PM'
  AND s.s_state              = 'CA'
  AND cd.cd_gender           = 'M'
  AND ws.ws_quantity         >= 10
  AND sr.sr_return_amt       > 100.00
  AND wp.wp_web_page_sk IN (SELECT wp_web_page_sk FROM page_home)
GROUP BY GROUPING SETS (
    (d.d_year, s.s_state),
    (cd.cd_gender),
    ()
)
LIMIT 100
