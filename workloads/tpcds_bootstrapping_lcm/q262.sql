SELECT
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    start_d.d_date AS promo_start_date,
    end_d.d_date AS promo_end_date,
    date_diff('day', start_d.d_date, end_d.d_date) AS promo_duration_days,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cs.cs_quantity) AS avg_quantity_per_order,
    (SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt) - SUM(p.p_cost)) AS net_profit_after_returns_and_promo
FROM catalog_sales cs
JOIN date_dim sold_d
    ON cs.cs_sold_date_sk = sold_d.d_date_sk
JOIN date_dim ship_d
    ON cs.cs_ship_date_sk = ship_d.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim start_d
    ON p.p_start_date_sk = start_d.d_date_sk
JOIN date_dim end_d
    ON p.p_end_date_sk = end_d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = sold_d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = end_d.d_date_sk
WHERE sold_d.d_year = 2022
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    start_d.d_date,
    end_d.d_date
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY net_profit_after_returns_and_promo DESC
LIMIT 100
