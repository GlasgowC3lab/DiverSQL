WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk AS date_sk,
        'Store' AS channel,
        ss.ss_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_class AS item_class,
        i.i_item_id AS item_id,
        COALESCE(s.s_store_name, 'UNKNOWN') AS store_name,
        CAST(NULL AS VARCHAR) AS page_desc,
        CAST(NULL AS VARCHAR) AS page_url,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk, ss.ss_item_sk, i.i_item_desc, i.i_class, i.i_item_id, s.s_store_name
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk AS date_sk,
        'Catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_class AS item_class,
        i.i_item_id AS item_id,
        CAST(NULL AS VARCHAR) AS store_name,
        COALESCE(cp.cp_description, 'UNKNOWN') AS page_desc,
        CAST(NULL AS VARCHAR) AS page_url,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_qty,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk, cs.cs_item_sk, i.i_item_desc, i.i_class, i.i_item_id, cp.cp_description
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk AS date_sk,
        'Web' AS channel,
        ws.ws_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_class AS item_class,
        i.i_item_id AS item_id,
        CAST(NULL AS VARCHAR) AS store_name,
        CAST(NULL AS VARCHAR) AS page_desc,
        COALESCE(wp.wp_url, 'UNKNOWN') AS page_url,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk, ws.ws_item_sk, i.i_item_desc, i.i_class, i.i_item_id, wp.wp_url
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    c.d_year,
    c.d_month_seq,
    c.channel,
    c.item_sk,
    CONCAT_WS(' - ', c.item_desc, c.item_class, CAST(c.item_sk AS VARCHAR)) AS full_item_desc,
    c.total_sales,
    c.total_profit,
    CASE WHEN c.total_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
    c.total_profit / nullif(c.total_sales, 0) AS profit_margin,
    c.total_qty,
    c.orders,
    (SELECT COALESCE(SUM(r.return_quantity), 0)
     FROM (
        SELECT sr_return_quantity AS return_quantity, sr_item_sk AS item_sk, sr_returned_date_sk AS date_sk FROM store_returns
        UNION ALL
        SELECT cr_return_quantity, cr_item_sk, cr_returned_date_sk FROM catalog_returns
        UNION ALL
        SELECT wr_return_quantity, wr_item_sk, wr_returned_date_sk FROM web_returns
     ) r
     WHERE r.item_sk = c.item_sk
       AND r.date_sk = c.date_sk) AS total_return_qty,
    LAG(c.total_profit) OVER (PARTITION BY c.channel, c.item_sk ORDER BY c.d_year, c.d_month_seq) AS prev_month_profit,
    c.total_profit - LAG(c.total_profit) OVER (PARTITION BY c.channel, c.item_sk ORDER BY c.d_year, c.d_month_seq) AS profit_change,
    CASE
        WHEN c.total_profit - LAG(c.total_profit) OVER (PARTITION BY c.channel, c.item_sk ORDER BY c.d_year, c.d_month_seq) > 0 THEN 'UP'
        WHEN c.total_profit - LAG(c.total_profit) OVER (PARTITION BY c.channel, c.item_sk ORDER BY c.d_year, c.d_month_seq) < 0 THEN 'DOWN'
        ELSE 'FLAT'
    END AS profit_trend,
    ROW_NUMBER() OVER (PARTITION BY c.channel, c.d_year, c.d_month_seq ORDER BY c.total_profit / nullif(c.total_sales, 0) DESC) AS profit_margin_rank,
    AVG(c.total_profit) OVER (PARTITION BY c.channel) AS avg_profit_per_channel,
    AVG(c.total_sales) OVER (PARTITION BY c.channel) AS avg_sales_per_channel,
    UPPER(c.item_desc) AS item_desc_upper,
    COALESCE(c.store_name, c.page_desc, c.page_url, 'N/A') AS ancillary_info
FROM combined c
WHERE c.total_sales > 0
ORDER BY c.channel, c.d_year DESC, c.d_month_seq DESC, profit_margin_rank
LIMIT 100
