WITH sales_returns AS (
    SELECT
        ds.d_year AS sales_year,
        dsh.d_year AS ship_year,
        st.s_store_id,
        st.s_city,
        sm.sm_type AS ship_mode,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_net_loss,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(cs.cs_quantity) AS avg_quantity_sold,
        AVG(wr.wr_return_quantity) AS avg_quantity_returned
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN date_dim dsh ON cs.cs_ship_date_sk = dsh.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = dsh.d_date_sk
    JOIN store st ON st.s_closed_date_sk = ds.d_date_sk
    GROUP BY
        ds.d_year,
        dsh.d_year,
        st.s_store_id,
        st.s_city,
        sm.sm_type
    HAVING SUM(cs.cs_ext_sales_price) > 1000
)
SELECT
    sales_year,
    ship_year,
    s_store_id,
    s_city,
    ship_mode,
    total_orders,
    total_sales,
    total_discount,
    total_ship_cost,
    total_net_profit,
    total_return_amount,
    total_return_net_loss,
    total_return_tax,
    (total_net_profit - total_return_net_loss) AS net_profit_after_returns,
    CASE WHEN total_sales = 0 THEN 0 ELSE total_return_amount / total_sales END AS return_to_sales_ratio,
    avg_quantity_sold,
    avg_quantity_returned,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank_by_store
FROM sales_returns
ORDER BY net_profit_after_returns DESC
LIMIT 100
