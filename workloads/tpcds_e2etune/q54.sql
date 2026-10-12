WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_coupon_amt) AS total_coupon,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910  -- example surrogate date range
    GROUP BY cs.cs_call_center_sk
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 50000
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    cc.cc_county,
    agg.total_sales,
    agg.total_profit,
    agg.total_profit / NULLIF(agg.total_sales, 0) AS profit_margin,
    agg.avg_quantity,
    agg.transaction_cnt,
    RANK() OVER (ORDER BY agg.total_sales DESC) AS sales_rank
FROM cs_agg agg
JOIN call_center cc
    ON agg.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'TX'
ORDER BY sales_rank
LIMIT 10
