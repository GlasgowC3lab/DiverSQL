SELECT
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_division_name,
    t.t_shift,
    wp.wp_type,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_fee) AS total_fee,
    SUM(sr.sr_store_credit) AS total_store_credit,
    SUM(sr.sr_return_tax) AS total_return_tax,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MAX(d_wp_access.d_date) AS latest_access_date,
    SUM(CASE WHEN d_closure.d_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS store_closed_on_date_cnt
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closure
  ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_division_name,
    t.t_shift,
    wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
