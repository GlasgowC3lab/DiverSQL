SELECT
    i.i_brand,
    i.i_category,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    ws.web_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS num_returns,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    CASE
        WHEN SUM(wr.wr_return_amt) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
        ELSE NULL
    END AS loss_to_return_ratio
FROM web_returns AS wr
JOIN date_dim AS d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item AS i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site AS ws
    ON ws.web_open_date_sk = d.d_date_sk
   AND ws.web_close_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2023
  AND wr.wr_net_loss > 0
GROUP BY
    i.i_brand,
    i.i_category,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    ws.web_name
ORDER BY total_net_loss DESC
LIMIT 200
