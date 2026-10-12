SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    CASE
        WHEN t_ret.t_hour < 12 THEN 'Morning'
        WHEN t_ret.t_hour < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS part_of_day,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fees,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_amount_per_item,
    SUM(CASE WHEN cr.cr_returned_time_sk % 2 = 0 THEN cr.cr_return_amount ELSE 0 END) AS even_time_returns
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
  AND cc.cc_state = s.s_state
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    CASE
        WHEN t_ret.t_hour < 12 THEN 'Morning'
        WHEN t_ret.t_hour < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END
HAVING SUM(cr.cr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 50
