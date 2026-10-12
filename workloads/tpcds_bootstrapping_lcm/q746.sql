SELECT
    d_return.d_date AS return_date,
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    p.p_promo_name AS promo_name,
    p.p_purpose AS promo_purpose,
    COUNT(wr.wr_order_number) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    CASE
        WHEN SUM(wr.wr_return_quantity) = 0 THEN NULL
        ELSE SUM(wr.wr_return_amt) / SUM(wr.wr_return_quantity)
    END AS avg_return_amount_per_qty,
    d_open.d_year AS call_center_open_year,
    d_end.d_year AS promo_end_year
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    d_return.d_date,
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_purpose,
    d_open.d_year,
    d_end.d_year
ORDER BY total_return_amount DESC
LIMIT 100
