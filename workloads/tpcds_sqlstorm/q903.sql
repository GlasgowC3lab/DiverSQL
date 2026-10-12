WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS total_net_profit,
        COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0) + COALESCE(ws.ws_quantity, 0) AS total_quantity,
        COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS first_sale_date_sk
    FROM
        customer c
        LEFT JOIN (
            SELECT
                cs_bill_customer_sk AS cust_sk,
                SUM(cs_net_profit) AS cs_net_profit,
                SUM(cs_quantity) AS cs_quantity,
                MIN(cs_sold_date_sk) AS cs_sold_date_sk
            FROM catalog_sales
            GROUP BY cs_bill_customer_sk
        ) cs ON c.c_customer_sk = cs.cust_sk
        LEFT JOIN (
            SELECT
                ss_customer_sk AS cust_sk,
                SUM(ss_net_profit) AS ss_net_profit,
                SUM(ss_quantity) AS ss_quantity,
                MIN(ss_sold_date_sk) AS ss_sold_date_sk
            FROM store_sales
            GROUP BY ss_customer_sk
        ) ss ON c.c_customer_sk = ss.cust_sk
        LEFT JOIN (
            SELECT
                ws_bill_customer_sk AS cust_sk,
                SUM(ws_net_profit) AS ws_net_profit,
                SUM(ws_quantity) AS ws_quantity,
                MIN(ws_sold_date_sk) AS ws_sold_date_sk
            FROM web_sales
            GROUP BY ws_bill_customer_sk
        ) ws ON c.c_customer_sk = ws.cust_sk
    WHERE
        c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL
),
customer_region AS (
    SELECT
        cr.c_customer_sk,
        d.d_year,
        COALESCE(cr.c_current_addr_sk, 0) AS addr_sk
    FROM
        customer cr
        LEFT JOIN date_dim d ON cr.c_first_sales_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
),
top_customers AS (
    SELECT
        s.c_customer_sk,
        s.c_customer_id,
        s.total_net_profit,
        s.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.c_customer_id ORDER BY s.total_net_profit DESC) AS rn,
        CASE
            WHEN s.total_net_profit > 0 THEN 'PROFITABLE'
            WHEN s.total_net_profit < 0 THEN 'LOSS'
            ELSE 'NEUTRAL'
        END AS profit_status,
        CONCAT('CUST-', CAST(s.c_customer_id AS VARCHAR)) AS custom_key
    FROM sales_agg s
)
SELECT
    tc.c_customer_id,
    tc.custom_key,
    tc.profit_status,
    tc.total_net_profit,
    tc.total_quantity,
    cr.d_year,
    COALESCE(
        (SELECT AVG(total_net_profit) FROM sales_agg sa WHERE sa.c_customer_id = tc.c_customer_id AND sa.total_net_profit IS NOT NULL),
        0
    ) AS avg_customer_profit,
    COALESCE(
        (SELECT MAX(ss.ss_net_paid) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk),
        0
    ) AS max_store_payment,
    COALESCE(
        (SELECT SUM(crd.cr_refunded_cash) FROM catalog_returns crd WHERE crd.cr_refunded_customer_sk = tc.c_customer_sk),
        0
    ) AS total_refunded_cash,
    CASE
        WHEN cr.addr_sk IS NULL THEN 'UNKNOWN_ADDR'
        ELSE CONCAT('ADDR_', CAST(cr.addr_sk AS VARCHAR))
    END AS address_key
FROM
    top_customers tc
    LEFT JOIN customer_region cr ON tc.c_customer_sk = cr.c_customer_sk
WHERE
    tc.rn = 1
    AND (tc.total_quantity > 10 OR tc.total_net_profit IS NOT NULL)
UNION ALL
SELECT
    c.c_customer_id,
    CONCAT('CUST-', CAST(c.c_customer_id AS VARCHAR)),
    CASE WHEN (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) = 0 THEN 'NO_SALES' ELSE 'HAS_SALES' END,
    0.0,
    0,
    d.d_year,
    0.0,
    0.0,
    0.0,
    'NO_ADDR'
FROM
    customer c
    LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
WHERE
    NOT EXISTS (SELECT 1 FROM sales_agg sa WHERE sa.c_customer_sk = c.c_customer_sk)
    AND c.c_preferred_cust_flag = 'Y'
    AND d.d_year BETWEEN 2000 AND 2002
ORDER BY total_net_profit DESC
