SELECT
    p.p_promo_name,
    p.p_channel_tv,
    sm.sm_carrier,
    r.r_reason_desc,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_item_sk) AS distinct_items,
    AVG(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS pct_discount_active
FROM promotion p
JOIN reason r
    ON p.p_promo_sk = r.r_reason_sk
JOIN ship_mode sm
    ON p.p_channel_tv = sm.sm_type
WHERE p.p_channel_email = 'N'
  AND p.p_channel_press = 'N'
  AND p.p_start_date_sk BETWEEN 20200101 AND 20201231
  AND p.p_end_date_sk BETWEEN 20210101 AND 20211231
GROUP BY
    p.p_promo_name,
    p.p_channel_tv,
    sm.sm_carrier,
    r.r_reason_desc
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 50
