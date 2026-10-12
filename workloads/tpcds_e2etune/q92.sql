WITH
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450826
    GROUP BY ss.ss_customer_sk
),
store_return_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(sr.sr_return_quantity) AS return_quantity
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450826
    GROUP BY sr.sr_customer_sk
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450826
      AND sm.sm_type = 'AIR'
    GROUP BY cs.cs_bill_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450826
      AND sm.sm_type = 'AIR'
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    COALESCE(s.store_net_profit, 0) - COALESCE(r.store_return_loss, 0) + COALESCE(cat.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    COALESCE(s.store_discount, 0) + COALESCE(cat.catalog_discount, 0) + COALESCE(w.web_discount, 0) AS total_discount,
    COALESCE(s.store_quantity, 0) + COALESCE(cat.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) - COALESCE(r.return_quantity, 0) AS total_quantity,
    CASE
        WHEN (COALESCE(s.store_quantity, 0) + COALESCE(cat.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) - COALESCE(r.return_quantity, 0)) > 0
        THEN (COALESCE(s.store_discount, 0) + COALESCE(cat.catalog_discount, 0) + COALESCE(w.web_discount, 0)) / (COALESCE(s.store_quantity, 0) + COALESCE(cat.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) - COALESCE(r.return_quantity, 0))
        ELSE 0
    END AS avg_discount_per_item
FROM customer c
LEFT JOIN store_agg s ON c.c_customer_sk = s.customer_sk
LEFT JOIN store_return_agg r ON c.c_customer_sk = r.customer_sk
LEFT JOIN catalog_agg cat ON c.c_customer_sk = cat.customer_sk
LEFT JOIN web_agg w ON c.c_customer_sk = w.customer_sk
WHERE (COALESCE(s.store_quantity, 0) + COALESCE(cat.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) - COALESCE(r.return_quantity, 0)) >= 10
ORDER BY total_net_profit DESC
LIMIT 100
