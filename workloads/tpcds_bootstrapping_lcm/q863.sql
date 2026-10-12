SELECT
    ca_bill.ca_state AS state,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_margin,
    ROUND(SUM(wr.wr_net_loss) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS loss_to_sales_ratio,
    AVG(d_ship.d_moy) AS avg_ship_month,
    MAX(ca_ship.ca_city) AS shipping_city_example,
    MIN(ca_refund.ca_state) AS refund_state_example
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY ca_bill.ca_state, d_sold.d_year, d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
