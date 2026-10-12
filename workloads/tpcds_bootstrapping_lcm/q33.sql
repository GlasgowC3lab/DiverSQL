WITH sales_agg AS (
    SELECT 
        sm.sm_carrier,
        d_ship.d_year,
        d_ship.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        AVG(s.s_number_employees) AS avg_store_employees
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    GROUP BY sm.sm_carrier, d_ship.d_year, d_ship.d_month_seq
)
SELECT 
    sm_carrier,
    d_year,
    month_seq,
    total_sales_inc_tax,
    total_return_loss,
    order_count,
    avg_store_employees,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_sales_inc_tax - total_return_loss) DESC) AS sales_profit_rank
FROM sales_agg
ORDER BY total_sales_inc_tax DESC
LIMIT 100
