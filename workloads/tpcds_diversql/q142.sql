WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS sale_cnt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship_tax > (
        SELECT MAX(cs2.cs_net_paid_inc_ship_tax) FROM catalog_sales cs2
    ) * 0.5
    GROUP BY cs.cs_catalog_page_sk, cs.cs_sold_time_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    td.t_hour,
    td.t_sub_shift,
    sa.total_sales,
    sa.avg_profit,
    sa.sale_cnt,
    CASE WHEN sa.avg_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_customer_sk = cp.cp_catalog_page_sk
    ) AS related_sales_cnt,
    (
        SELECT AVG(cs_all.cs_net_paid)
        FROM catalog_sales cs_all
    ) AS overall_avg_net_paid
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON sa.cs_sold_time_sk = td.t_time_sk
WHERE cp.cp_type = 'quarterly'
  AND td.t_sub_shift = 'morning'
  AND td.t_hour BETWEEN 8 AND 12
  AND sa.total_sales > 1000
ORDER BY sa.total_sales DESC, cp.cp_catalog_page_id
LIMIT 100
