SELECT
    p.p_promo_id,
    p.p_promo_name,
    CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'No Email' END AS email_channel,
    CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'No TV' END AS tv_channel,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  AND cs.cs_ship_mode_sk IN (3, 8, 15)
  AND p.p_channel_email = 'Y'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    p.p_channel_tv
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY profit_rank
LIMIT 10
