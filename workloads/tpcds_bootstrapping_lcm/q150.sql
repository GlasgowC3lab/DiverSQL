SELECT
    s.s_store_id,
    d_sold.d_year,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    cd_refunded.cd_credit_rating AS refunded_credit_rating,
    CASE
        WHEN cs.cs_net_paid >= 500 THEN 'high'
        WHEN cs.cs_net_paid >= 200 THEN 'mid'
        ELSE 'low'
    END AS net_paid_bucket,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amt,
    ROUND(SUM(wr.wr_return_amt) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS return_to_sales_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    s.s_store_id,
    d_sold.d_year,
    cd_bill.cd_gender,
    cd_ship.cd_marital_status,
    cd_refunded.cd_credit_rating,
    CASE
        WHEN cs.cs_net_paid >= 500 THEN 'high'
        WHEN cs.cs_net_paid >= 200 THEN 'mid'
        ELSE 'low'
    END
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
