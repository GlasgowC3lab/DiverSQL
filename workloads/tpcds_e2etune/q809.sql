WITH daily_returns AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        SUM(sr_net_loss) AS total_return_loss,
        SUM(sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr_customer_sk) AS distinct_return_customers
    FROM store_returns
    WHERE sr_net_loss > 0
      AND sr_return_quantity > 0
      AND sr_store_sk IN (176, 466, 751)
    GROUP BY sr_returned_date_sk
),

daily_sales AS (
    SELECT
        ws_sold_date_sk AS date_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        SUM(ws_quantity) AS total_sales_qty,
        COUNT(DISTINCT ws_bill_customer_sk) AS distinct_sales_customers
    FROM web_sales
    WHERE ws_net_profit > 0
      AND ws_quantity > 0
      AND ws_warehouse_sk IN (1, 2, 3)
    GROUP BY ws_sold_date_sk
)
SELECT
    d.date_sk,
    d.total_return_loss,
    d.total_return_qty,
    d.distinct_return_customers,
    s.total_sales_profit,
    s.total_sales_qty,
    s.distinct_sales_customers,
    CASE WHEN s.total_sales_profit = 0 THEN NULL
         ELSE d.total_return_loss / s.total_sales_profit END AS loss_to_profit_ratio
FROM daily_returns d
JOIN daily_sales s
  ON d.date_sk = s.date_sk
WHERE d.total_return_loss > 100
  AND s.total_sales_profit > 500
ORDER BY loss_to_profit_ratio DESC
LIMIT 100
