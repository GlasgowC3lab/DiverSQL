SELECT
    s.s_store_id,
    s.s_store_name,
    dr.d_date AS return_date,
    td.t_hour,
    td.t_minute,
    p.p_promo_name,
    p.p_discount_active,
    dsp.d_date AS promo_start_date,
    dep.d_date AS promo_end_date,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_tax) AS total_return_tax
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN time_dim td
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN promotion p
    ON dr.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim dsp
    ON p.p_start_date_sk = dsp.d_date_sk
JOIN date_dim dep
    ON p.p_end_date_sk = dep.d_date_sk
WHERE s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND dr.d_year = 2023
GROUP BY
    s.s_store_id,
    s.s_store_name,
    dr.d_date,
    td.t_hour,
    td.t_minute,
    p.p_promo_name,
    p.p_discount_active,
    dsp.d_date,
    dep.d_date
ORDER BY total_return_amt DESC
LIMIT 100
