WITH
months AS (
    SELECT DISTINCT d_year, d_month_seq
    FROM date_dim
),
locations AS (
    SELECT s_store_sk AS location_id,
           s_store_name AS location_name,
           'Store' AS location_type
    FROM store
    UNION ALL
    SELECT cc_call_center_sk,
           cc_name,
           'CallCenter'
    FROM call_center
    UNION ALL
    SELECT web_site_sk,
           web_name,
           'WebSite'
    FROM web_site
),
store_sales_monthly AS (
    SELECT 
        ss.ss_store_sk AS location_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS profit,
        'Store' AS location_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
catalog_sales_monthly AS (
    SELECT 
        cs.cs_call_center_sk AS location_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS profit,
        'CallCenter' AS location_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_call_center_sk, d.d_year, d.d_month_seq
),
web_sales_monthly AS (
    SELECT 
        ws.ws_web_site_sk AS location_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS profit,
        'WebSite' AS location_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_site_sk, d.d_year, d.d_month_seq
),
sales_agg AS (
    SELECT location_id, location_type, d_year, d_month_seq, profit FROM store_sales_monthly
    UNION ALL
    SELECT location_id, location_type, d_year, d_month_seq, profit FROM catalog_sales_monthly
    UNION ALL
    SELECT location_id, location_type, d_year, d_month_seq, profit FROM web_sales_monthly
),
full_grid AS (
    SELECT l.location_id,
           l.location_name,
           l.location_type,
           m.d_year,
           m.d_month_seq
    FROM locations l
    CROSS JOIN months m
),
grid_with_profit AS (
    SELECT 
        fg.location_id,
        fg.location_name,
        fg.location_type,
        fg.d_year,
        fg.d_month_seq,
        COALESCE(sa.profit, 0) AS profit
    FROM full_grid fg
    LEFT JOIN sales_agg sa
        ON fg.location_id = sa.location_id
        AND fg.location_type = sa.location_type
        AND fg.d_year = sa.d_year
        AND fg.d_month_seq = sa.d_month_seq
),
final_calc AS (
    SELECT 
        location_id,
        CONCAT(location_name, ' (', location_type, ')') AS location_descr,
        d_year,
        d_month_seq,
        profit,
        LAG(profit) OVER (PARTITION BY location_type, location_id ORDER BY d_year, d_month_seq) AS prev_month_profit,
        CASE 
            WHEN LAG(profit) OVER (PARTITION BY location_type, location_id ORDER BY d_year, d_month_seq) IS NULL
                 OR LAG(profit) OVER (PARTITION BY location_type, location_id ORDER BY d_year, d_month_seq) = 0
            THEN NULL
            ELSE (profit - LAG(profit) OVER (PARTITION BY location_type, location_id ORDER BY d_year, d_month_seq))
                 / LAG(profit) OVER (PARTITION BY location_type, location_id ORDER BY d_year, d_month_seq)
        END AS mom_pct_change,
        RANK() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank_year,
        (SELECT AVG(profit) FROM grid_with_profit g2 WHERE g2.d_year = gc.d_year AND g2.d_month_seq = gc.d_month_seq) AS avg_monthly_profit,
        CASE 
            WHEN profit > 0 THEN 'POS'
            WHEN profit < 0 THEN 'NEG'
            ELSE 'ZERO'
        END AS profit_sign
    FROM grid_with_profit gc
),
top_locations AS (
    SELECT 
        location_descr,
        SUM(profit) AS total_profit
    FROM final_calc
    GROUP BY location_descr
    ORDER BY total_profit DESC
    LIMIT 5
)
SELECT 
    fc.location_descr,
    fc.d_year,
    fc.d_month_seq,
    fc.profit,
    fc.prev_month_profit,
    ROUND(fc.mom_pct_change * 100, 2) AS mom_pct_change_perc,
    fc.profit_rank_year,
    ROUND(fc.avg_monthly_profit, 2) AS avg_monthly_profit,
    fc.profit_sign
FROM final_calc fc
WHERE fc.profit_rank_year <= 10
UNION ALL
SELECT 
    tl.location_descr,
    NULL,
    NULL,
    tl.total_profit,
    NULL,
    NULL,
    NULL,
    NULL,
    'TOTAL'
FROM top_locations tl
ORDER BY d_year NULLS LAST, d_month_seq NULLS LAST, profit DESC
