SELECT
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year AS store_closed_year,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_sales_discount,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
    COUNT(DISTINCT wr.wr_order_number) AS num_web_returns,
    (SUM(cs.cs_net_paid) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) AS net_sales_after_returns,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    AVG(cs.cs_ext_tax) AS avg_sales_tax,
    SUM(CASE WHEN cs.cs_quantity > 1 THEN cs.cs_quantity ELSE 0 END) AS total_multi_item_quantity,
    SUM(sr.sr_return_quantity) AS total_store_return_quantity,
    SUM(wr.wr_return_quantity) AS total_web_return_quantity
FROM store s
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sr.d_date_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_wr ON cs.cs_ship_date_sk = d_wr.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY net_sales_after_returns DESC
LIMIT 100
