WITH catalog_sales_electronics AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           date_trunc('month', date_add('day', cs.cs_sold_date_sk - 2451545, DATE '2000-01-01')) AS sale_month,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2458849 AND 2459214
      AND p.p_discount_active = 'Y'
),
web_sales_electronics AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           date_trunc('month', date_add('day', ws.ws_sold_date_sk - 2451545, DATE '2000-01-01')) AS sale_month,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Electronics'
      AND ws.ws_sold_date_sk BETWEEN 2458849 AND 2459214
      AND p.p_discount_active = 'Y'
),
store_returns_electronics AS (
    SELECT sr.sr_customer_sk AS cust_sk,
           date_trunc('month', date_add('day', sr.sr_returned_date_sk - 2451545, DATE '2000-01-01')) AS sale_month,
           -sr.sr_net_loss AS profit
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND sr.sr_returned_date_sk BETWEEN 2458849 AND 2459214
),
web_returns_electronics AS (
    SELECT wr.wr_refunded_customer_sk AS cust_sk,
           date_trunc('month', date_add('day', wr.wr_returned_date_sk - 2451545, DATE '2000-01-01')) AS sale_month,
           -wr.wr_net_loss AS profit
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND wr.wr_returned_date_sk BETWEEN 2458849 AND 2459214
),
combined AS (
    SELECT * FROM catalog_sales_electronics
    UNION ALL
    SELECT * FROM web_sales_electronics
    UNION ALL
    SELECT * FROM store_returns_electronics
    UNION ALL
    SELECT * FROM web_returns_electronics
),
monthly_profit AS (
    SELECT cust_sk,
           sale_month,
           SUM(profit) AS net_profit
    FROM combined
    GROUP BY cust_sk, sale_month
    HAVING SUM(profit) > 0
),
ranked_monthly AS (
    SELECT cust_sk,
           sale_month,
           net_profit,
           ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY net_profit DESC) AS month_rank
    FROM monthly_profit
)
SELECT c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       r.sale_month,
       r.net_profit,
       r.month_rank
FROM ranked_monthly r
JOIN customer c ON r.cust_sk = c.c_customer_sk
WHERE r.month_rank <= 10
ORDER BY r.sale_month, r.month_rank
