WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_sold_time_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_net_profit > 0
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    SUM(fs.cs_net_profit) AS total_catalog_net_profit,
    COUNT(*) AS transaction_count,
    RANK() OVER (ORDER BY SUM(fs.cs_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_gmt_offset = -5.00
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state
ORDER BY total_catalog_net_profit DESC
LIMIT 10
