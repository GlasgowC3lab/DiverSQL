WITH years AS (
    SELECT DISTINCT d_year AS year FROM date_dim
),
sales_union AS (
    SELECT 
        ss.ss_store_sk AS loc_sk,
        'Store' AS loc_type,
        d.d_year AS year,
        COALESCE(ss.ss_net_profit, 0) AS net_profit,
        COALESCE(ss.ss_quantity, 0) AS quantity,
        COALESCE(ss.ss_ext_sales_price, 0) AS sales_amount,
        ss.ss_ticket_number AS txn_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT 
        cs.cs_call_center_sk AS loc_sk,
        'CallCenter' AS loc_type,
        d.d_year AS year,
        COALESCE(cs.cs_net_profit, 0) AS net_profit,
        COALESCE(cs.cs_quantity, 0) AS quantity,
        COALESCE(cs.cs_ext_sales_price, 0) AS sales_amount,
        cs.cs_order_number AS txn_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT 
        ws.ws_web_page_sk AS loc_sk,
        'Web' AS loc_type,
        d.d_year AS year,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(ws.ws_quantity, 0) AS quantity,
        COALESCE(ws.ws_ext_sales_price, 0) AS sales_amount,
        ws.ws_order_number AS txn_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT 
        loc_type,
        loc_sk,
        year,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        SUM(sales_amount) AS total_sales,
        COUNT(DISTINCT txn_id) AS transaction_cnt
    FROM sales_union
    GROUP BY loc_type, loc_sk, year
),
full_agg AS (
    SELECT 
        y.year,
        loc.loc_type,
        loc.loc_sk,
        COALESCE(a.total_profit, 0) AS total_profit,
        COALESCE(a.total_quantity, 0) AS total_quantity,
        COALESCE(a.total_sales, 0) AS total_sales,
        COALESCE(a.transaction_cnt, 0) AS transaction_cnt
    FROM years y
    CROSS JOIN (SELECT DISTINCT loc_type, loc_sk FROM aggregated) loc
    LEFT JOIN aggregated a 
        ON a.loc_type = loc.loc_type 
        AND a.loc_sk = loc.loc_sk 
        AND a.year = y.year
),
prev_years AS (
    SELECT 
        fa.loc_type,
        fa.loc_sk,
        fa.year,
        fa.total_profit,
        fa.total_quantity,
        fa.total_sales,
        fa.transaction_cnt,
        LAG(fa.total_profit) OVER (PARTITION BY fa.loc_type, fa.loc_sk ORDER BY fa.year) AS prev_year_profit,
        LAG(fa.total_sales) OVER (PARTITION BY fa.loc_type, fa.loc_sk ORDER BY fa.year) AS prev_year_sales
    FROM full_agg fa
),
profit_change AS (
    SELECT 
        loc_type,
        loc_sk,
        year,
        total_profit,
        total_sales,
        transaction_cnt,
        prev_year_profit,
        prev_year_sales,
        CASE 
            WHEN prev_year_profit IS NULL THEN NULL
            ELSE (total_profit - prev_year_profit) / NULLIF(prev_year_profit, 0) * 100
        END AS profit_pct_change,
        CASE 
            WHEN prev_year_sales IS NULL THEN NULL
            ELSE (total_sales - prev_year_sales) / NULLIF(prev_year_sales, 0) * 100
        END AS sales_pct_change
    FROM prev_years
),
ranked AS (
    SELECT 
        loc_type,
        loc_sk,
        year,
        total_profit,
        total_sales,
        transaction_cnt,
        profit_pct_change,
        sales_pct_change,
        ROW_NUMBER() OVER (PARTITION BY loc_type, year ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (PARTITION BY loc_type ORDER BY total_sales DESC) AS sales_rank_global
    FROM profit_change
)
SELECT 
    r.loc_type,
    CASE 
        WHEN r.loc_type = 'Store' THEN s.s_store_name
        WHEN r.loc_type = 'CallCenter' THEN cc.cc_name
        WHEN r.loc_type = 'Web' THEN wp.wp_url
        ELSE CAST(r.loc_sk AS VARCHAR)
    END AS location_name,
    r.year,
    r.total_profit,
    r.total_sales,
    r.transaction_cnt,
    ROUND(r.profit_pct_change, 2) AS profit_pct_change,
    ROUND(r.sales_pct_change, 2) AS sales_pct_change,
    r.profit_rank,
    r.sales_rank_global,
    CONCAT('Y', CAST(r.year AS VARCHAR), '-', r.loc_type) AS composite_key,
    COALESCE(
        (SELECT SUM(sr.sr_net_loss)
         FROM store_returns sr
         JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
         WHERE sr.sr_store_sk = r.loc_sk AND dr.d_year = r.year), 0) AS total_store_returns_loss,
    CASE 
        WHEN r.total_profit IS NULL OR r.total_profit = 0 THEN NULL
        ELSE r.total_sales / r.total_profit
    END AS sales_to_profit_ratio
FROM ranked r
LEFT JOIN store s ON r.loc_type = 'Store' AND r.loc_sk = s.s_store_sk
LEFT JOIN call_center cc ON r.loc_type = 'CallCenter' AND r.loc_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON r.loc_type = 'Web' AND r.loc_sk = wp.wp_web_page_sk
WHERE r.year >= (SELECT MAX(d_year) - 5 FROM date_dim)
  AND (r.total_profit > 10000 OR r.total_sales > 50000)
ORDER BY r.year DESC, r.total_profit DESC
LIMIT 100
