WITH promo_sales AS (
    SELECT
        cs.cs_promo_sk AS cs_promo_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_coupon_amt) AS total_coupon,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_coupon_amt) AS avg_coupon
    FROM catalog_sales cs
    WHERE cs.cs_ship_date_sk BETWEEN 2450840 AND 2450906
      AND cs.cs_wholesale_cost > 50
    GROUP BY cs.cs_promo_sk
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    p.p_promo_name,
    p.p_channel_email,
    ps.order_cnt,
    ps.total_net_paid,
    ps.total_profit,
    ROUND(ps.total_profit / NULLIF(ps.total_net_paid, 0) * 100, 2) AS profit_margin_pct,
    RANK() OVER (ORDER BY ps.total_profit DESC) AS profit_rank
FROM promotion p
JOIN promo_sales ps
    ON p.p_promo_sk = ps.cs_promo_sk
WHERE p.p_discount_active = 'Y'
ORDER BY profit_rank
LIMIT 20
