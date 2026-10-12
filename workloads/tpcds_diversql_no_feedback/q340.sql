WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_ship_date_sk BETWEEN 2450800 AND 2450900
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_quantity > 0
      AND cs.cs_list_price IS NOT NULL
      AND cs.cs_ext_discount_amt < 500
    GROUP BY
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
)
SELECT
    w.w_warehouse_name,
    hd.hd_vehicle_count,
    p.p_promo_name,
    cp.cp_department,
    SUM(cs_agg.total_sales) AS sum_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS sum_returns,
    SUM(ss.ss_net_profit) AS sum_store_profit,
    (SUM(cs_agg.total_sales) - SUM(COALESCE(cr.cr_return_amount, 0)) + SUM(ss.ss_net_profit)) AS net_metric
FROM cs_agg
FULL OUTER JOIN catalog_returns cr
    ON cs_agg.cs_order_number = cr.cr_order_number
JOIN warehouse w
    ON COALESCE(cs_agg.cs_warehouse_sk, cr.cr_warehouse_sk) = w.w_warehouse_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
    ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cp.cp_department = 'Electronics'
  AND hd.hd_income_band_sk > 5
  AND ss.ss_quantity > 0
GROUP BY
    w.w_warehouse_name,
    hd.hd_vehicle_count,
    p.p_promo_name,
    cp.cp_department
HAVING (SUM(cs_agg.total_sales) - SUM(COALESCE(cr.cr_return_amount, 0)) + SUM(ss.ss_net_profit)) > 10000
ORDER BY net_metric DESC
LIMIT 100
