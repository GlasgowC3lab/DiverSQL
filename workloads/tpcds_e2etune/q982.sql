SELECT
    w.w_state AS warehouse_state,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM
    catalog_sales cs
JOIN
    promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN
    warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN
    time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
WHERE
    t.t_hour BETWEEN 18 AND 23
    AND cs.cs_net_profit > 0
    AND p.p_discount_active = 'Y'
GROUP BY
    w.w_state,
    p.p_promo_name
HAVING
    SUM(cs.cs_net_profit) > 1000
ORDER BY
    w.w_state,
    total_net_profit DESC
LIMIT 100
