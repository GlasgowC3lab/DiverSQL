SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_date AS activity_date,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT wr.wr_order_number) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    (SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns,
    AVG(t.t_hour) AS avg_hour_of_day,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 0
        THEN ROUND(COALESCE(SUM(wr.wr_return_amt), 0) / SUM(cs.cs_ext_sales_price), 4)
        ELSE 0
    END AS return_to_sales_ratio,
    ROUND(
        100 * SUM(cs.cs_ext_sales_price) /
        NULLIF(SUM(cs.cs_ext_sales_price) + COALESCE(SUM(wr.wr_return_amt), 0), 0),
        2
    ) AS sales_percentage_of_total
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_date
ORDER BY net_sales_after_returns DESC
LIMIT 100
