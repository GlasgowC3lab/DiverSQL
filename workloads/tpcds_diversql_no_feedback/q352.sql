WITH agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 50
      AND cs.cs_quantity >= 2
      AND cs.cs_ext_ship_cost < 1000
      AND cs.cs_ext_discount_amt > 0
      AND cs.cs_net_paid_inc_tax > 0
      AND cs.cs_coupon_amt = 0
    GROUP BY cs.cs_call_center_sk, cs.cs_promo_sk, cs.cs_catalog_page_sk
),

discount_levels AS (
    SELECT 0.05 AS discount_rate UNION ALL SELECT 0.10 UNION ALL SELECT 0.15
)
SELECT
    cc.cc_name,
    p.p_promo_name,
    cp.cp_department,
    agg.total_sales,
    agg.total_profit,
    agg.order_cnt,
    dl.discount_rate,
    agg.total_sales * (1 - dl.discount_rate) AS sales_after_discount
FROM agg
JOIN call_center cc
    ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON agg.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN discount_levels dl
WHERE agg.total_sales > (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
)
ORDER BY agg.total_sales DESC
LIMIT 100
