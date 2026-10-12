WITH
store_sales_agg AS (
    SELECT
        ss_customer_sk AS customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(*) AS store_order_cnt,
        MAX(d.d_date) AS last_store_purchase_date,
        SUM(ss_net_profit) AS net_store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(*) AS catalog_order_cnt,
        MAX(d.d_date) AS last_catalog_purchase_date,
        SUM(cs_net_profit) AS net_catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs_bill_customer_sk
),
web_sales_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(*) AS web_order_cnt,
        MAX(d.d_date) AS last_web_purchase_date,
        SUM(ws_net_profit) AS net_web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws_bill_customer_sk
),
combined_sales AS (
    SELECT
        COALESCE(s.customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(s.total_store_sales, 0) + COALESCE(c.total_catalog_sales, 0) + COALESCE(w.total_web_sales, 0) AS total_sales,
        COALESCE(s.store_order_cnt, 0) + COALESCE(c.catalog_order_cnt, 0) + COALESCE(w.web_order_cnt, 0) AS total_orders,
        GREATEST(
            COALESCE(s.last_store_purchase_date, DATE '1970-01-01'),
            COALESCE(c.last_catalog_purchase_date, DATE '1970-01-01'),
            COALESCE(w.last_web_purchase_date, DATE '1970-01-01')
        ) AS last_purchase_date,
        COALESCE(s.net_store_profit, 0) + COALESCE(c.net_catalog_profit, 0) + COALESCE(w.net_web_profit, 0) AS total_net_profit
    FROM store_sales_agg s
    FULL OUTER JOIN catalog_sales_agg c ON s.customer_sk = c.customer_sk
    FULL OUTER JOIN web_sales_agg w ON COALESCE(s.customer_sk, c.customer_sk) = w.customer_sk
),
high_return_customers AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        ROUND(
            1.0 * (SELECT SUM(sr.sr_return_quantity) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) /
            NULLIF((SELECT SUM(ss_quantity) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk), 0)
        , 2) AS store_return_ratio,
        ROUND(
            1.0 * (SELECT SUM(cr.cr_return_quantity) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = c.c_customer_sk) /
            NULLIF((SELECT SUM(cs_quantity) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk), 0)
        , 2) AS catalog_return_ratio,
        ROUND(
            1.0 * (SELECT SUM(wr.wr_return_quantity) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) /
            NULLIF((SELECT SUM(ws_quantity) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk), 0)
        , 2) AS web_return_ratio
    FROM customer c
),
ranked_customers AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        COALESCE(cs.total_sales, 0) AS total_sales,
        COALESCE(cs.total_orders, 0) AS total_orders,
        cs.last_purchase_date,
        COALESCE(cs.total_net_profit, 0) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(cs.total_sales, 0) DESC) AS sales_rank,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    LEFT JOIN combined_sales cs ON c.c_customer_sk = cs.customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
loyal_customers AS (
    SELECT
        rc.customer_sk,
        rc.full_name,
        rc.ca_state,
        rc.total_sales,
        rc.total_orders,
        CASE WHEN rc.total_orders > 0 THEN rc.total_sales / rc.total_orders ELSE NULL END AS avg_sales_per_order,
        rc.last_purchase_date,
        rc.total_net_profit,
        CASE
            WHEN rc.last_purchase_date IS NOT NULL AND date_diff('day', rc.last_purchase_date, DATE '2024-10-01') <= 30 THEN 'Active'
            WHEN rc.last_purchase_date IS NOT NULL AND date_diff('day', rc.last_purchase_date, DATE '2024-10-01') BETWEEN 31 AND 90 THEN 'Dormant'
            ELSE 'Inactive'
        END AS activity_status,
        CASE
            WHEN rc.total_sales > 10000 THEN 'Gold'
            WHEN rc.total_sales > 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS loyalty_tier
    FROM ranked_customers rc
    WHERE rc.sales_rank <= 10 OR rc.total_sales > 2000
)
SELECT
    lc.customer_sk,
    lc.full_name,
    lc.ca_state,
    lc.total_sales,
    lc.total_orders,
    lc.avg_sales_per_order,
    lc.last_purchase_date,
    lc.total_net_profit,
    lc.activity_status,
    lc.loyalty_tier,
    hr.store_return_ratio,
    hr.catalog_return_ratio,
    hr.web_return_ratio
FROM loyal_customers lc
LEFT JOIN high_return_customers hr ON lc.customer_sk = hr.customer_sk
WHERE (hr.store_return_ratio IS NOT NULL AND hr.store_return_ratio > 0.2)
   OR (hr.catalog_return_ratio IS NOT NULL AND hr.catalog_return_ratio > 0.2)
   OR (hr.web_return_ratio IS NOT NULL AND hr.web_return_ratio > 0.2)
UNION ALL
SELECT
    NULL AS customer_sk,
    'TOTAL' AS full_name,
    NULL AS ca_state,
    SUM(lc.total_sales) AS total_sales,
    SUM(lc.total_orders) AS total_orders,
    CASE WHEN SUM(lc.total_orders) > 0 THEN SUM(lc.total_sales) / SUM(lc.total_orders) ELSE NULL END AS avg_sales_per_order,
    NULL AS last_purchase_date,
    SUM(lc.total_net_profit) AS total_net_profit,
    NULL AS activity_status,
    NULL AS loyalty_tier,
    NULL AS store_return_ratio,
    NULL AS catalog_return_ratio,
    NULL AS web_return_ratio
FROM loyal_customers lc
ORDER BY total_sales DESC
LIMIT 100
