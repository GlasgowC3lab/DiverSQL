SELECT
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    cs_agg.total_net_paid,
    cs_agg.order_cnt
FROM (
    SELECT
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    GROUP BY cs_promo_sk, cs_call_center_sk, cs_ship_mode_sk
    HAVING SUM(cs_net_paid) > 76.80
) AS cs_agg
JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_channel_tv = 'N'
  AND cc.cc_state = 'NC'
