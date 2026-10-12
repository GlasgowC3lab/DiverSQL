SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(ca_refunded.ca_zip) AS min_refunded_zip,
    MAX(ca_returning.ca_zip) AS max_returning_zip
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY s.s_store_id, s.s_city, s.s_state, d.d_year, d.d_month_seq
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
