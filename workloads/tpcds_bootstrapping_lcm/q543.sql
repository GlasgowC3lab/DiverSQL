SELECT
    s.s_store_name,
    d_sold.d_year AS sales_year,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales_orders,
    COUNT(DISTINCT wr.wr_order_number) AS num_return_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_net_loss,
    (SUM(cs.cs_net_profit) - SUM(wr.wr_net_loss)) AS net_profit_after_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    (COUNT(DISTINCT wr.wr_order_number) * 1.0) / NULLIF(COUNT(DISTINCT cs.cs_order_number), 0) AS return_rate
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE d_sold.d_year BETWEEN 1995 AND 1998
  AND s.s_state IN ('CA', 'TX', 'NY')
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    cd_refunded.cd_gender,
    cd_returning.cd_gender
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
