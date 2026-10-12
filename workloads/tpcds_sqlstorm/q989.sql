WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
combined AS (
    SELECT
        COALESCE(s.d_year, c.d_year, w.d_year) AS d_year,
        COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq) AS d_month_seq,
        COALESCE(s.i_item_id, c.i_item_id, w.i_item_id) AS i_item_id,
        s.store_net_profit,
        c.catalog_net_profit,
        w.web_net_profit,
        s.store_net_paid,
        c.catalog_net_paid,
        w.web_net_paid,
        s.store_sales_cnt,
        c.catalog_sales_cnt,
        w.web_sales_cnt
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c
        ON s.d_year = c.d_year
        AND s.d_month_seq = c.d_month_seq
        AND s.i_item_id = c.i_item_id
    FULL OUTER JOIN web_agg w
        ON COALESCE(s.d_year, c.d_year) = w.d_year
        AND COALESCE(s.d_month_seq, c.d_month_seq) = w.d_month_seq
        AND COALESCE(s.i_item_id, c.i_item_id) = w.i_item_id
)
SELECT
    d_year,
    d_month_seq,
    i_item_id,
    store_net_profit,
    catalog_net_profit,
    web_net_profit,
    (COALESCE(store_net_profit, 0) + COALESCE(catalog_net_profit, 0) + COALESCE(web_net_profit, 0)) AS total_net_profit,
    (COALESCE(store_sales_cnt, 0) + COALESCE(catalog_sales_cnt, 0) + COALESCE(web_sales_cnt, 0)) AS total_sales_cnt
FROM combined
WHERE d_year = 2001
ORDER BY total_net_profit DESC
LIMIT 100
