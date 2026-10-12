WITH
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_by_date_store AS (
    SELECT
        date_sk,
        store_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(orders) AS total_orders,
        SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY date_sk, store_sk
),
store_latest_return AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        COALESCE(
            (SELECT MAX(sr.sr_returned_date_sk)
             FROM store_returns sr
             WHERE sr.sr_store_sk = s.s_store_sk),
            -1) AS latest_return_date_sk
    FROM store s
),
ranked_sales AS (
    SELECT
        d.d_date,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        COALESCE(sal.total_net_profit, 0) AS net_profit,
        COALESCE(sal.total_net_paid, 0) AS net_paid,
        COALESCE(sal.total_orders, 0) AS orders,
        COALESCE(sal.total_quantity, 0) AS quantity,
        CASE WHEN COALESCE(sal.total_net_profit,0) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        COALESCE(sal.total_net_profit,0) / NULLIF(COALESCE(sal.total_quantity,0),0) AS profit_per_unit,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_label,
        SUBSTRING(s.s_store_name FROM 1 FOR 5) AS store_name_prefix,
        RANK() OVER (PARTITION BY d.d_date ORDER BY COALESCE(sal.total_net_profit,0) DESC) AS profit_rank,
        lr.latest_return_date_sk,
        (SELECT COUNT(*)
         FROM store_returns sr
         WHERE sr.sr_store_sk = s.s_store_sk
           AND sr.sr_returned_date_sk = d.d_date_sk) AS returns_on_date,
        CASE
            WHEN EXISTS (SELECT 1 FROM store_returns sr
                         WHERE sr.sr_store_sk = s.s_store_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk)
            THEN 0 ELSE 1
        END AS unreturned_flag
    FROM date_dim d
    CROSS JOIN store s
    LEFT JOIN sales_by_date_store sal
        ON sal.date_sk = d.d_date_sk
        AND (sal.store_sk = s.s_store_sk OR (sal.store_sk IS NULL AND s.s_store_sk IS NULL))
    LEFT JOIN store_latest_return lr
        ON lr.s_store_sk = s.s_store_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND (d.d_year BETWEEN 1999 AND 2002 OR d.d_year IS NULL)
      AND MOD(COALESCE(s.s_gmt_offset,0), 2) = 0
)
SELECT *
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY d_date, profit_rank
