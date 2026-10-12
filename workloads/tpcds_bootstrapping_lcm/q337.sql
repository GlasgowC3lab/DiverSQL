SELECT
    s.s_store_name,
    d.d_year,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    CASE
        WHEN cd_refunded.cd_purchase_estimate < 1000 THEN 'Low'
        WHEN cd_refunded.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_bucket,
    COUNT(*) AS return_cnt,
    SUM(w.wr_return_amt) AS total_return_amt,
    SUM(w.wr_net_loss) AS total_net_loss,
    AVG(w.wr_return_quantity) AS avg_return_qty,
    SUM(w.wr_fee) AS total_fee,
    SUM(w.wr_return_tax) AS total_tax,
    COUNT(DISTINCT w.wr_order_number) AS distinct_orders
FROM web_returns w
JOIN date_dim d
    ON w.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded
    ON w.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON w.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
GROUP BY
    s.s_store_name,
    d.d_year,
    cd_refunded.cd_gender,
    cd_returning.cd_gender,
    CASE
        WHEN cd_refunded.cd_purchase_estimate < 1000 THEN 'Low'
        WHEN cd_refunded.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END
HAVING SUM(w.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
