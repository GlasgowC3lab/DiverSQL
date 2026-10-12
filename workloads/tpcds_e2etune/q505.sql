WITH catalog_monthly AS (
    SELECT
        cs_bill_customer_sk AS cust_sk,
        date_trunc('month', date_add('day', cs_sold_date_sk, date('1970-01-01'))) AS month,
        SUM(cs_net_profit) AS catalog_profit,
        SUM(cs_quantity) AS catalog_qty,
        AVG(cs_sales_price) AS avg_catalog_price,
        COUNT(*) AS catalog_orders
    FROM catalog_sales
    WHERE cs_sales_price > 30.00
      AND cs_ext_discount_amt < 5.00
    GROUP BY cs_bill_customer_sk, date_trunc('month', date_add('day', cs_sold_date_sk, date('1970-01-01')))
),
web_monthly AS (
    SELECT
        ws_bill_customer_sk AS cust_sk,
        date_trunc('month', date_add('day', ws_sold_date_sk, date('1970-01-01'))) AS month,
        SUM(ws_net_profit) AS web_profit,
        SUM(ws_quantity) AS web_qty,
        AVG(ws_sales_price) AS avg_web_price,
        COUNT(*) AS web_orders
    FROM web_sales
    WHERE ws_sales_price > 30.00
      AND ws_ext_discount_amt < 5.00
    GROUP BY ws_bill_customer_sk, date_trunc('month', date_add('day', ws_sold_date_sk, date('1970-01-01')))
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cm.month,
    cm.catalog_profit,
    wm.web_profit,
    (cm.catalog_profit + wm.web_profit) AS total_profit,
    cm.catalog_qty,
    wm.web_qty,
    RANK() OVER (PARTITION BY cm.month ORDER BY (cm.catalog_profit + wm.web_profit) DESC) AS profit_rank
FROM catalog_monthly cm
JOIN web_monthly wm
    ON cm.cust_sk = wm.cust_sk
   AND cm.month = wm.month
JOIN customer c
    ON cm.cust_sk = c.c_customer_sk
WHERE cm.catalog_qty >= 5
  AND wm.web_qty >= 5
ORDER BY cm.month, profit_rank
LIMIT 200
