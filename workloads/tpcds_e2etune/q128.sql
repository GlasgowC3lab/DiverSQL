WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND ws.ws_ship_mode_sk = 1
    GROUP BY d.d_year, d.d_month_seq
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND cp.cp_type = 'monthly'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.month_seq,
    s.total_sales,
    r.total_returns,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_revenue,
    s.total_profit,
    CASE WHEN s.sales_orders > 0 THEN s.total_profit / s.sales_orders ELSE NULL END AS avg_profit_per_order,
    CASE WHEN r.return_orders > 0 THEN r.total_returns / r.return_orders ELSE NULL END AS avg_return_loss_per_order
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year AND s.month_seq = r.month_seq
ORDER BY net_revenue DESC
LIMIT 10
