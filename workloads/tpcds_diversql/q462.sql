WITH filtered_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ship_mode_sk,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_coupon_amt,
    cc.cc_market_manager,
    cc.cc_gmt_offset,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    hd.hd_buy_potential,
    i.i_category,
    i.i_brand,
    sm.sm_type
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cc.cc_market_manager = 'John Melendez'
    AND cc.cc_gmt_offset = -5.00
    AND hd.hd_dep_count >= 2
    AND hd.hd_vehicle_count BETWEEN 0 AND 3
    AND hd.hd_buy_potential = '501-1000'
    AND i.i_category = 'Electronics'
    AND sm.sm_type = 'AIR'
    AND cs.cs_coupon_amt > (
          SELECT MAX(cs2.cs_coupon_amt)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 20200101
        )
    AND EXISTS (
          SELECT 1
          FROM catalog_sales cs3
          WHERE cs3.cs_item_sk = cs.cs_item_sk
            AND cs3.cs_sold_date_sk = cs.cs_sold_date_sk
            AND cs3.cs_quantity > 0
        )
)
SELECT *
FROM (
  SELECT
    f.i_category,
    f.cc_market_manager,
    SUM(f.cs_ext_sales_price) AS total_sales,
    AVG(f.cs_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(f.cs_quantity) > 100 THEN 'HIGH' ELSE 'LOW' END AS quantity_flag,
    ROW_NUMBER() OVER (PARTITION BY f.i_category ORDER BY SUM(f.cs_ext_sales_price) DESC) AS rn
  FROM filtered_sales f
  GROUP BY f.i_category, f.cc_market_manager
  HAVING SUM(f.cs_ext_sales_price) > 10000
  UNION DISTINCT
  SELECT
    f.i_category,
    f.cc_market_manager,
    SUM(f.cs_ext_sales_price) AS total_sales,
    AVG(f.cs_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(f.cs_quantity) > 100 THEN 'HIGH' ELSE 'LOW' END AS quantity_flag,
    ROW_NUMBER() OVER (PARTITION BY f.i_category ORDER BY SUM(f.cs_ext_sales_price) DESC) AS rn
  FROM filtered_sales f
  GROUP BY f.i_category, f.cc_market_manager
  HAVING SUM(f.cs_ext_sales_price) <= 10000
) u
WHERE u.rn <= 3
ORDER BY u.total_sales DESC
OFFSET 10 LIMIT 100
