WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_promo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        MIN(cs_ext_tax) AS min_tax,
        MAX(cs_ext_tax) AS max_tax
    FROM catalog_sales
    WHERE cs_ext_tax > 20.00
      AND cs_ext_list_price >= 1000.00
      AND cs_quantity BETWEEN 1 AND 10
    GROUP BY cs_call_center_sk, cs_promo_sk
)
SELECT
    cc.cc_name,
    cc.cc_division_name,
    p.p_promo_name,
    agg.total_sales,
    agg.total_profit,
    agg.order_cnt,
    agg.min_tax,
    agg.max_tax
FROM cs_agg agg
JOIN call_center cc
    ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON agg.cs_promo_sk = p.p_promo_sk
WHERE cc.cc_division_name IN ('cally', 'ese')
  AND cc.cc_mkt_id = 2
  AND p.p_channel_tv = 'N'
  AND p.p_item_sk IN (75314, 2044)
  AND p.p_start_date_sk BETWEEN 2450150 AND 2450600
  AND agg.total_sales > 5000.00
  AND agg.cs_call_center_sk NOT IN (
        SELECT cs_call_center_sk
        FROM catalog_sales
        WHERE cs_quantity > 1000
    )
ORDER BY agg.total_sales DESC
