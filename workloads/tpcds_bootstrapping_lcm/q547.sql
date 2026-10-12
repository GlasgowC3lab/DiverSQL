SELECT
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    s.s_store_name,
    w.web_name,
    r.r_reason_desc,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    (SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax)) AS total_return_amount_excl_tax,
    CASE
        WHEN SUM(wr.wr_return_quantity) > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    SUM(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_amt ELSE 0 END) AS high_qty_return_amount,
    (SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0)) AS avg_amount_per_item,
    (SUM(wr.wr_return_amt) - SUM(wr.wr_fee) - SUM(wr.wr_return_tax)) / NULLIF(SUM(wr.wr_return_amt), 0) AS net_margin_ratio
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_ret.d_date_sk
   AND w.web_close_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2020
  AND s.s_floor_space > 5000
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_store_name,
    w.web_name,
    r.r_reason_desc
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
