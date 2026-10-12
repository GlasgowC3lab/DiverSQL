SELECT
    s.s_market_desc,
    dr.d_year,
    CASE WHEN dr.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    i.i_category,
    i.i_brand,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_amt - wr.wr_fee) AS net_return_amt,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_discount_cost,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(p.p_response_target) AS total_response_target,
    SUM(p.p_end_date_sk - p.p_start_date_sk) AS total_promo_days,
    SUM(s.s_tax_percentage * wr.wr_return_amt / 100) AS total_tax_amount,
    ROUND(SUM(s.s_floor_space) / 1000.0, 2) AS floor_space_k
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim dp_start
    ON p.p_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end
    ON p.p_end_date_sk = dp_end.d_date_sk
CROSS JOIN store s
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
WHERE dr.d_year >= 2020
GROUP BY
    s.s_market_desc,
    dr.d_year,
    CASE WHEN dr.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    i.i_category,
    i.i_brand
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 200
