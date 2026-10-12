SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT wr.wr_order_number) AS total_orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wp.wp_image_count) AS total_image_count,
    MIN(d.d_date) AS min_date,
    MAX(d.d_date) AS max_date
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    s.s_state,
    s.s_city
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
