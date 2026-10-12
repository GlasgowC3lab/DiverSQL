SELECT
    d.d_year AS return_year,
    d.d_month_seq AS return_month,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE WHEN cd_refunded.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS refunded_gender,
    CASE WHEN cd_returning.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS returning_gender,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(CASE WHEN cd_refunded.cd_credit_rating = 'A' THEN wr.wr_return_amt ELSE 0 END) AS credit_A_return_amount,
    SUM(CASE WHEN i.i_current_price > 100 THEN wr.wr_return_quantity * i.i_current_price ELSE 0 END) AS high_price_return_value
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND i.i_category IS NOT NULL
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE WHEN cd_refunded.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    CASE WHEN cd_returning.cd_gender = 'M' THEN 'Male' ELSE 'Female' END
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
