WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS store_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_warehouse_sk AS store_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
),
date_info AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2002
),
store_details AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        s_country,
        s_gmt_offset
    FROM store
),
sales_monthly AS (
    SELECT
        su.store_sk,
        di.d_year,
        di.d_month_seq,
        SUM(su.net_profit) AS total_profit,
        SUM(su.net_paid) AS total_paid,
        SUM(su.quantity) AS total_quantity,
        COUNT(DISTINCT su.item_sk) AS distinct_items_sold,
        SUM(CASE WHEN su.channel = 'store' THEN su.net_profit ELSE 0 END) AS store_profit,
        SUM(CASE WHEN su.channel = 'catalog' THEN su.net_profit ELSE 0 END) AS catalog_profit,
        SUM(CASE WHEN su.channel = 'web' THEN su.net_profit ELSE 0 END) AS web_profit,
        AVG(su.net_profit) AS avg_profit_per_tx,
        array_join(array_agg(DISTINCT su.channel), ',') AS channels_used
    FROM sales_union su
    JOIN date_info di ON su.date_sk = di.d_date_sk
    GROUP BY su.store_sk, di.d_year, di.d_month_seq
),
profit_with_lag AS (
    SELECT
        sm.*,
        LAG(sm.total_profit) OVER (PARTITION BY sm.store_sk ORDER BY sm.d_year, sm.d_month_seq) AS prev_month_profit,
        CASE
            WHEN LAG(sm.total_profit) OVER (PARTITION BY sm.store_sk ORDER BY sm.d_year, sm.d_month_seq) IS NULL THEN NULL
            WHEN sm.total_profit >= LAG(sm.total_profit) OVER (PARTITION BY sm.store_sk ORDER BY sm.d_year, sm.d_month_seq) * 1.10 THEN 'Significant Increase'
            WHEN sm.total_profit <= LAG(sm.total_profit) OVER (PARTITION BY sm.store_sk ORDER BY sm.d_year, sm.d_month_seq) * 0.90 THEN 'Significant Decrease'
            ELSE 'Stable'
        END AS profit_trend
    FROM sales_monthly sm
),
top_item_per_store_month AS (
    SELECT
        su.store_sk,
        di.d_year,
        di.d_month_seq,
        su.item_sk,
        SUM(su.quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY su.store_sk, di.d_year, di.d_month_seq ORDER BY SUM(su.quantity) DESC) AS rn
    FROM sales_union su
    JOIN date_info di ON su.date_sk = di.d_date_sk
    GROUP BY su.store_sk, di.d_year, di.d_month_seq, su.item_sk
),
top_item_filtered AS (
    SELECT
        t.store_sk,
        t.d_year,
        t.d_month_seq,
        t.item_sk,
        t.total_quantity
    FROM top_item_per_store_month t
    WHERE t.rn = 1
),
store_summary AS (
    SELECT
        pwl.store_sk,
        pwl.d_year,
        pwl.d_month_seq,
        COALESCE(sd.s_store_name, 'Unknown Store') AS store_name,
        COALESCE(sd.s_city, 'Unknown City') AS city,
        COALESCE(sd.s_state, 'Unknown State') AS state,
        CONCAT(COALESCE(sd.s_store_name, '??'), ' (', COALESCE(sd.s_city, ''), ')') AS store_label,
        pwl.total_profit,
        pwl.prev_month_profit,
        pwl.profit_trend,
        pwl.store_profit,
        pwl.catalog_profit,
        pwl.web_profit,
        pwl.total_paid,
        pwl.total_quantity,
        pwl.distinct_items_sold,
        pwl.avg_profit_per_tx,
        pwl.channels_used,
        COALESCE(tif.item_sk, -1) AS top_item_sk,
        tif.total_quantity AS top_item_quantity,
        CASE WHEN tif.item_sk IS NULL THEN 'No Sales' ELSE 'Has Sales' END AS top_item_status
    FROM profit_with_lag pwl
    LEFT JOIN store_details sd ON pwl.store_sk = sd.s_store_sk
    LEFT JOIN top_item_filtered tif
        ON pwl.store_sk = tif.store_sk
        AND pwl.d_year = tif.d_year
        AND pwl.d_month_seq = tif.d_month_seq
)
SELECT
    ss.store_name,
    ss.store_label,
    ss.city,
    ss.state,
    ss.d_year,
    ss.d_month_seq,
    ss.total_profit,
    ss.prev_month_profit,
    ss.profit_trend,
    ss.store_profit,
    ss.catalog_profit,
    ss.web_profit,
    ss.total_paid,
    ss.total_quantity,
    ss.distinct_items_sold,
    ss.avg_profit_per_tx,
    ss.channels_used,
    ss.top_item_sk,
    i.i_product_name,
    ss.top_item_quantity,
    ss.top_item_status,
    CASE WHEN ss.total_quantity = 0 THEN 0 ELSE ss.total_profit / NULLIF(ss.total_quantity, 0) END AS profit_per_item,
    CASE WHEN ss.total_quantity = 0 THEN NULL ELSE ss.total_paid / ss.total_quantity END AS avg_paid_per_quantity
FROM store_summary ss
LEFT JOIN item i ON ss.top_item_sk = i.i_item_sk
WHERE ss.d_year = 2002
ORDER BY ss.total_profit DESC
FETCH FIRST 100 ROWS ONLY
