SELECT
    CONCAT(cd_sr.cd_gender, '-', cd_sr.cd_marital_status) AS gender_marital,
    s.s_state,
    date_format(sr_date.d_date, '%Y-%m') AS year_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(sr.sr_return_amt + wr.wr_return_amt) AS total_return_amount,
    AVG(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee END) AS avg_store_fee,
    AVG(CASE WHEN wr.wr_fee > 0 THEN wr.wr_fee END) AS avg_web_fee,
    SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_return_quantity ELSE 0 END) AS total_store_return_qty,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_quantity ELSE 0 END) AS total_web_return_qty
FROM store_returns sr
JOIN date_dim sr_date
    ON sr.sr_returned_date_sk = sr_date.d_date_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim store_closed_date
    ON s.s_closed_date_sk = store_closed_date.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = sr_date.d_date_sk
JOIN customer_demographics cd_wr_refunded
    ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN customer_demographics cd_wr_returning
    ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
WHERE sr_date.d_year = 2002
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    CONCAT(cd_sr.cd_gender, '-', cd_sr.cd_marital_status),
    s.s_state,
    date_format(sr_date.d_date, '%Y-%m')
HAVING COUNT(*) > 20
ORDER BY store_net_loss DESC
LIMIT 100
