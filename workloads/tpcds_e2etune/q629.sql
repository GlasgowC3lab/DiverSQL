SELECT
    cc.cc_name AS call_center,
    i.i_category AS category,
    w.w_state AS warehouse_state,
    CASE
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END AS promo_channel,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(t.t_hour) AS avg_sale_hour
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
WHERE
    cc.cc_manager = 'Bob Belcher'
    AND cc.cc_employees > 1000000
    AND i.i_category IN ('Electronics', 'Books', 'Clothing')
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    1, 2, 3, 4
HAVING
    SUM(cs.cs_net_profit) > 100000
ORDER BY
    total_profit DESC
LIMIT 10
