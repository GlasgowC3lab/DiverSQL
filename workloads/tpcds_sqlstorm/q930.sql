WITH
customer_sales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_name,
        COALESCE(cs_total.net_profit, 0) AS store_net_profit,
        COALESCE(cs_total.net_paid, 0) AS store_net_paid,
        COALESCE(ca_total.net_profit, 0) AS catalog_net_profit,
        COALESCE(ca_total.net_paid, 0) AS catalog_net_paid,
        COALESCE(ws_total.net_profit, 0) AS web_net_profit,
        COALESCE(ws_total.net_paid, 0) AS web_net_paid,
        COALESCE(cs_total.net_profit, 0) + COALESCE(ca_total.net_profit, 0) + COALESCE(ws_total.net_profit, 0) AS total_net_profit,
        COALESCE(cs_total.net_paid, 0) + COALESCE(ca_total.net_paid, 0) + COALESCE(ws_total.net_paid, 0) AS total_net_paid,
        CASE
            WHEN (COALESCE(cs_total.net_paid, 0) + COALESCE(ca_total.net_paid, 0) + COALESCE(ws_total.net_paid, 0)) = 0 THEN NULL
            ELSE (COALESCE(cs_total.net_profit, 0) + COALESCE(ca_total.net_profit, 0) + COALESCE(ws_total.net_profit, 0)) /
                 (COALESCE(cs_total.net_paid, 0) + COALESCE(ca_total.net_paid, 0) + COALESCE(ws_total.net_paid, 0))
        END AS profit_margin
    FROM customer c
    LEFT JOIN (
        SELECT ss_customer_sk AS c_customer_sk,
               SUM(ss_net_profit) AS net_profit,
               SUM(ss_net_paid) AS net_paid
        FROM store_sales
        GROUP BY ss_customer_sk
    ) cs_total ON cs_total.c_customer_sk = c.c_customer_sk
    LEFT JOIN (
        SELECT cs_bill_customer_sk AS c_customer_sk,
               SUM(cs_net_profit) AS net_profit,
               SUM(cs_net_paid) AS net_paid
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    ) ca_total ON ca_total.c_customer_sk = c.c_customer_sk
    LEFT JOIN (
        SELECT ws_bill_customer_sk AS c_customer_sk,
               SUM(ws_net_profit) AS net_profit,
               SUM(ws_net_paid) AS net_paid
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) ws_total ON ws_total.c_customer_sk = c.c_customer_sk
),
top_customers_by_channel AS (
    SELECT
        c_customer_sk,
        customer_name,
        'store' AS channel,
        store_net_profit AS net_profit,
        RANK() OVER (ORDER BY store_net_profit DESC) AS ch_rank
    FROM customer_sales
    WHERE store_net_profit > 0

    UNION ALL

    SELECT
        c_customer_sk,
        customer_name,
        'catalog' AS channel,
        catalog_net_profit AS net_profit,
        RANK() OVER (ORDER BY catalog_net_profit DESC) AS ch_rank
    FROM customer_sales
    WHERE catalog_net_profit > 0

    UNION ALL

    SELECT
        c_customer_sk,
        customer_name,
        'web' AS channel,
        web_net_profit AS net_profit,
        RANK() OVER (ORDER BY web_net_profit DESC) AS ch_rank
    FROM customer_sales
    WHERE web_net_profit > 0
),
ranked_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.customer_name,
        cs.total_net_profit,
        cs.profit_margin,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rn_total,
        MAX(CASE WHEN t.channel = 'store' THEN t.ch_rank END) OVER (PARTITION BY cs.c_customer_sk) AS store_rank,
        MAX(CASE WHEN t.channel = 'catalog' THEN t.ch_rank END) OVER (PARTITION BY cs.c_customer_sk) AS catalog_rank,
        MAX(CASE WHEN t.channel = 'web' THEN t.ch_rank END) OVER (PARTITION BY cs.c_customer_sk) AS web_rank
    FROM customer_sales cs
    LEFT JOIN top_customers_by_channel t
        ON t.c_customer_sk = cs.c_customer_sk
),
customer_recent_activity AS (
    SELECT
        c.c_customer_sk,
        MAX(d.d_date) AS last_purchase_date,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_txn_cnt,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_txn_cnt,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_txn_cnt
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk)
    GROUP BY c.c_customer_sk
),
final_result AS (
    SELECT
        r.c_customer_sk,
        r.customer_name,
        r.total_net_profit,
        r.profit_margin,
        r.store_rank,
        r.catalog_rank,
        r.web_rank,
        ca.last_purchase_date,
        ca.store_txn_cnt,
        ca.catalog_txn_cnt,
        ca.web_txn_cnt,
        CASE
            WHEN r.store_rank IS NOT NULL AND r.store_rank <= 10 THEN 'Top Store'
            WHEN r.catalog_rank IS NOT NULL AND r.catalog_rank <= 10 THEN 'Top Catalog'
            WHEN r.web_rank IS NOT NULL AND r.web_rank <= 10 THEN 'Top Web'
            ELSE 'Other'
        END AS tier,
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_customer_sk = r.c_customer_sk) AS avg_store_profit,
        (SELECT COUNT(*)
         FROM store_sales ss2
         WHERE ss2.ss_customer_sk = r.c_customer_sk
           AND ss2.ss_sold_date_sk >= (
               SELECT d2.d_date_sk
               FROM date_dim d2
               WHERE d2.d_date = DATE '2024-10-01' - INTERVAL '1' YEAR
           )
        ) AS store_txn_last_year
    FROM ranked_customers r
    LEFT JOIN customer_recent_activity ca ON ca.c_customer_sk = r.c_customer_sk
    WHERE r.rn_total = 1 AND ((r.profit_margin > 0.15 AND r.total_net_profit > 1000) OR (r.profit_margin IS NULL AND r.total_net_profit > 2000))
)
SELECT *
FROM final_result
ORDER BY total_net_profit DESC
LIMIT 100
