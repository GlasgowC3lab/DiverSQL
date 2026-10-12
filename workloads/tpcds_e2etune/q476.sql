WITH warehouse_year_profit AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        w.w_state,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_adj
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_warehouse_name, w.w_state
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
), ranked AS (
    SELECT
        d_year,
        w_warehouse_name,
        w_state,
        total_sales_profit,
        total_return_loss,
        total_sales_amount,
        net_profit_adj,
        net_profit_adj / NULLIF(total_sales_amount, 0) AS profit_margin,
        RANK() OVER (PARTITION BY d_year ORDER BY net_profit_adj DESC) AS profit_rank
    FROM warehouse_year_profit
)
SELECT
    d_year,
    w_warehouse_name,
    w_state,
    total_sales_profit,
    total_return_loss,
    total_sales_amount,
    net_profit_adj,
    profit_margin,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
