WITH ship_mode_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_discount_amt > 0
    GROUP BY cs.cs_ship_mode_sk, cs.cs_warehouse_sk
)
SELECT
    ranked.w_warehouse_name,
    ranked.sm_type,
    ranked.total_sales,
    ranked.total_profit,
    ranked.sales_cnt,
    ranked.avg_discount,
    ranked.profit_margin,
    ranked.profit_rank
FROM (
    SELECT
        w.w_warehouse_name,
        sm.sm_type,
        ss.total_sales,
        ss.total_profit,
        ss.sales_cnt,
        ss.avg_discount,
        ss.total_profit / NULLIF(ss.total_sales, 0) AS profit_margin,
        RANK() OVER (PARTITION BY sm.sm_type ORDER BY ss.total_profit DESC) AS profit_rank
    FROM ship_mode_sales ss
    JOIN ship_mode sm ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ss.cs_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_type IN ('AIR', 'RAIL')
      AND w.w_country = 'United States'
) ranked
WHERE ranked.profit_rank <= 5
ORDER BY ranked.sm_type, ranked.profit_rank
