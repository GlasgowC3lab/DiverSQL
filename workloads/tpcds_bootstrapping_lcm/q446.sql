SELECT
    d.d_year,
    d.d_month_seq,
    d.d_date,
    s.s_store_name,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.inv_quantity_on_hand > 0
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_date,
    s.s_store_name,
    cd_refunded.cd_gender,
    cd_returning.cd_gender
ORDER BY d.d_date DESC
LIMIT 100
