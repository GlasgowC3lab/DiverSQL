WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 5
      AND cs.cs_net_paid > 100
      AND cs.cs_ext_discount_amt < 20
      AND cs.cs_sold_date_sk BETWEEN 2452000 AND 2452100
)
SELECT
    w.w_warehouse_name,
    w.w_county,
    p.p_promo_name,
    t.t_sub_shift,
    COUNT(*) AS sales_transactions,
    SUM(base.cs_net_paid) AS total_net_paid,
    AVG(base.cs_net_paid) AS avg_net_paid,
    MIN(base.cs_net_profit) AS min_profit,
    MAX(base.cs_net_profit) AS max_profit
FROM base
JOIN time_dim t
    ON base.cs_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON base.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON base.cs_warehouse_sk = w.w_warehouse_sk
CROSS JOIN (VALUES (1), (2), (3)) AS mult(multiplier)
WHERE w.w_county = 'Daviess County'
  AND t.t_sub_shift = 'morning'
  AND p.p_channel_details LIKE '%High%'
  AND mult.multiplier = 2
GROUP BY w.w_warehouse_name, w.w_county, p.p_promo_name, t.t_sub_shift
ORDER BY total_net_paid DESC
LIMIT 100
