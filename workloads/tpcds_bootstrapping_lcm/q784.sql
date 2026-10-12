SELECT
    s.s_store_id,
    d.d_year,
    d.d_month_seq,
    (d.d_year * 100 + d.d_month_seq) AS year_month_key,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_sales_discount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(wr.wr_net_loss) AS net_profit_after_returns,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    COUNT(*) AS total_rows
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_ship_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND r.r_reason_desc IN ('Damaged', 'Defective', 'Not as described')
GROUP BY
    s.s_store_id,
    d.d_year,
    d.d_month_seq,
    (d.d_year * 100 + d.d_month_seq),
    r.r_reason_desc
HAVING SUM(cs.cs_net_paid) > 5000
ORDER BY total_sales_net_paid DESC
LIMIT 100
