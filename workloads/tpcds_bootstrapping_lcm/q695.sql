SELECT
    CONCAT(CAST(d_ret.d_year AS VARCHAR), '-', LPAD(CAST(d_ret.d_moy AS VARCHAR), 2, '0')) AS year_month,
    i.i_category,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN cd_ref.cd_credit_rating = 'A' THEN 1 ELSE 0 END) AS high_credit_refunded,
    SUM(CASE WHEN cd_ret.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_returning,
    SUM(CASE WHEN i.i_brand = 'BrandX' THEN wr.wr_return_amt ELSE 0 END) AS brandx_return_amt
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2015
GROUP BY
    CONCAT(CAST(d_ret.d_year AS VARCHAR), '-', LPAD(CAST(d_ret.d_moy AS VARCHAR), 2, '0')),
    i.i_category,
    s.s_state
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 200
