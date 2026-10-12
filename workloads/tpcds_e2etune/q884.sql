WITH returns_by_warehouse AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        SUM(cr.cr_store_credit) AS total_store_credit
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 1
      AND cr.cr_returning_customer_sk IN (6114601, 7882809, 502311)
    GROUP BY cr.cr_warehouse_sk
    HAVING SUM(cr.cr_net_loss) > 500
),
sales_by_warehouse AS (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_net_paid) AS total_sales_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ws.ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    r.total_return_loss,
    s.total_sales_profit,
    s.total_sales_paid,
    r.total_store_credit,
    r.distinct_return_orders,
    s.distinct_sales_orders,
    CASE WHEN s.total_sales_profit = 0 THEN NULL ELSE r.total_return_loss / s.total_sales_profit END AS loss_to_profit_ratio,
    ROUND(r.total_return_loss / NULLIF(s.total_sales_paid, 0), 4) AS loss_to_paid_ratio
FROM returns_by_warehouse r
JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN sales_by_warehouse s ON s.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
ORDER BY loss_to_profit_ratio DESC
LIMIT 50
