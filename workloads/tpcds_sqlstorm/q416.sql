WITH 
    store_sales_data AS (
        SELECT 
            'store' AS channel,
            ss.ss_sold_date_sk AS date_sk,
            d.d_year,
            ss.ss_item_sk AS item_sk,
            ss.ss_customer_sk AS customer_sk,
            ss.ss_store_sk AS location_sk,
            ss.ss_sales_price AS sales_price,
            ss.ss_quantity AS quantity,
            ss.ss_net_profit AS net_profit,
            COALESCE(ss.ss_sales_price * ss.ss_quantity, 0) AS line_total,
            CONCAT('ST', CAST(ss.ss_store_sk AS VARCHAR)) AS location_key,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_profit DESC) AS profit_rank,
            SUM(ss.ss_net_profit) OVER (PARTITION BY ss.ss_store_sk) AS total_profit,
            LAG(ss.ss_sales_price) OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk) AS prev_price_item
        FROM store_sales ss
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE ss.ss_quantity > 0
    ),
    catalog_sales_data AS (
        SELECT 
            'catalog' AS channel,
            cs.cs_sold_date_sk AS date_sk,
            d.d_year,
            cs.cs_item_sk AS item_sk,
            cs.cs_bill_customer_sk AS customer_sk,
            cs.cs_call_center_sk AS location_sk,
            cs.cs_sales_price AS sales_price,
            cs.cs_quantity AS quantity,
            cs.cs_net_profit AS net_profit,
            COALESCE(cs.cs_sales_price * cs.cs_quantity, 0) AS line_total,
            CONCAT('CC', CAST(cs.cs_call_center_sk AS VARCHAR)) AS location_key,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank,
            SUM(cs.cs_net_profit) OVER (PARTITION BY cs.cs_call_center_sk) AS total_profit,
            LAG(cs.cs_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk) AS prev_price_item
        FROM catalog_sales cs
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cs.cs_quantity > 0
    ),
    web_sales_data AS (
        SELECT 
            'web' AS channel,
            ws.ws_sold_date_sk AS date_sk,
            d.d_year,
            ws.ws_item_sk AS item_sk,
            ws.ws_bill_customer_sk AS customer_sk,
            ws.ws_web_page_sk AS location_sk,
            ws.ws_sales_price AS sales_price,
            ws.ws_quantity AS quantity,
            ws.ws_net_profit AS net_profit,
            COALESCE(ws.ws_sales_price * ws.ws_quantity, 0) AS line_total,
            CONCAT('WP', CAST(ws.ws_web_page_sk AS VARCHAR)) AS location_key,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
            SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_web_page_sk) AS total_profit,
            LAG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS prev_price_item
        FROM web_sales ws
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE ws.ws_quantity > 0
    ),
    combined_sales AS (
        SELECT * FROM store_sales_data
        UNION ALL
        SELECT * FROM catalog_sales_data
        UNION ALL
        SELECT * FROM web_sales_data
    ),
    store_returns_data AS (
        SELECT 
            'store' AS channel,
            sr.sr_returned_date_sk AS date_sk,
            d.d_year,
            sr.sr_item_sk AS item_sk,
            sr.sr_customer_sk AS customer_sk,
            sr.sr_store_sk AS location_sk,
            -sr.sr_return_amt AS line_total,
            -sr.sr_return_quantity AS quantity,
            -sr.sr_net_loss AS net_profit,
            CONCAT('ST', CAST(sr.sr_store_sk AS VARCHAR)) AS location_key
        FROM store_returns sr
        LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    ),
    catalog_returns_data AS (
        SELECT 
            'catalog' AS channel,
            cr.cr_returned_date_sk AS date_sk,
            d.d_year,
            cr.cr_item_sk AS item_sk,
            cr.cr_refunded_customer_sk AS customer_sk,
            cr.cr_call_center_sk AS location_sk,
            -cr.cr_return_amount AS line_total,
            -cr.cr_return_quantity AS quantity,
            -cr.cr_net_loss AS net_profit,
            CONCAT('CC', CAST(cr.cr_call_center_sk AS VARCHAR)) AS location_key
        FROM catalog_returns cr
        LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    ),
    web_returns_data AS (
        SELECT 
            'web' AS channel,
            wr.wr_returned_date_sk AS date_sk,
            d.d_year,
            wr.wr_item_sk AS item_sk,
            wr.wr_refunded_customer_sk AS customer_sk,
            wr.wr_web_page_sk AS location_sk,
            -wr.wr_return_amt AS line_total,
            -wr.wr_return_quantity AS quantity,
            -wr.wr_net_loss AS net_profit,
            CONCAT('WP', CAST(wr.wr_web_page_sk AS VARCHAR)) AS location_key
        FROM web_returns wr
        LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    ),
    returns AS (
        SELECT * FROM store_returns_data
        UNION ALL
        SELECT * FROM catalog_returns_data
        UNION ALL
        SELECT * FROM web_returns_data
    ),
    flagged_sales AS (
        SELECT 
            cs.channel,
            cs.date_sk,
            cs.d_year,
            cs.item_sk,
            cs.customer_sk,
            cs.location_sk,
            cs.sales_price,
            cs.quantity,
            cs.net_profit,
            cs.line_total,
            cs.location_key,
            cs.profit_rank,
            cs.total_profit,
            cs.prev_price_item,
            CASE 
                WHEN cs.line_total IS NULL THEN 'MISSING_SALES'
                WHEN cs.line_total < 0 THEN 'NEGATIVE_SALES'
                WHEN cs.profit_rank IS NULL THEN 'NO_RANK'
                ELSE 'OK'
            END AS quality_flag,
            CASE 
                WHEN REGEXP_LIKE(cs.location_key, '^ST[0-9]+$') THEN 'STORE_LOC'
                WHEN REGEXP_LIKE(cs.location_key, '^CC[0-9]+$') THEN 'CALL_CENTER_LOC'
                WHEN REGEXP_LIKE(cs.location_key, '^WP[0-9]+$') THEN 'WEB_PAGE_LOC'
                ELSE 'UNKNOWN_LOC'
            END AS location_type,
            cs.total_profit / NULLIF(cs.quantity, 0) AS avg_profit_per_quantity,
            NOT (NOT (cs.quantity > 0 AND cs.line_total > 0)) AS positive_sales_indicator
        FROM combined_sales cs
    ),
    merged AS (
        SELECT
            f.channel,
            f.date_sk,
            f.d_year,
            f.customer_sk,
            f.location_key,
            f.location_type,
            f.line_total,
            f.quantity,
            f.net_profit,
            CASE
                WHEN f.quality_flag = 'MISSING_SALES' THEN NULL
                ELSE f.line_total
            END AS adjusted_line_total,
            ROW_NUMBER() OVER (PARTITION BY f.channel, f.location_key ORDER BY f.d_year DESC, f.line_total DESC) AS rn,
            (SELECT SUM(f2.line_total)
             FROM flagged_sales f2
             WHERE f2.channel = f.channel
               AND f2.d_year = f.d_year) AS year_channel_total,
            CAST(COALESCE(CASE WHEN f.quality_flag = 'MISSING_SALES' THEN NULL ELSE f.line_total END, 0) AS DOUBLE) AS line_total_double
        FROM flagged_sales f
        WHERE f.quality_flag <> 'MISSING_SALES'
          AND (f.location_type IS NOT NULL AND f.location_type <> 'UNKNOWN_LOC')
    )
SELECT
    m.channel,
    m.d_year,
    m.location_key,
    m.location_type,
    MIN(m.adjusted_line_total) AS min_line_total,
    MAX(m.adjusted_line_total) AS max_line_total,
    AVG(m.adjusted_line_total) AS avg_line_total,
    SUM(m.adjusted_line_total) AS sum_line_total,
    COUNT(DISTINCT m.customer_sk) AS distinct_customers,
    SUM(CASE WHEN m.rn = 1 THEN m.adjusted_line_total ELSE 0 END) AS top_line_total,
    COALESCE(SUM(r.total_returns), 0) AS total_returns,
    (SUM(m.adjusted_line_total) - COALESCE(SUM(r.total_returns), 0)) / NULLIF(SUM(m.quantity), 0) AS net_per_quantity,
    GROUPING(m.channel) AS grp_channel,
    GROUPING(m.location_type) AS grp_loc_type
FROM merged m
LEFT JOIN (
    SELECT 
        channel,
        d_year,
        SUM(line_total) AS total_returns
    FROM returns
    GROUP BY channel, d_year
) r
  ON m.channel = r.channel AND m.d_year = r.d_year
GROUP BY GROUPING SETS ((m.channel, m.d_year, m.location_key, m.location_type), (m.channel, m.d_year), ())
HAVING SUM(m.adjusted_line_total) > 0
ORDER BY m.d_year DESC, sum_line_total DESC
LIMIT 100
