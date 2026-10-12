WITH filtered_data AS (
    SELECT
        cc.cc_company,
        i.i_brand,
        cd.cd_gender,
        cs.cs_net_paid,
        cr.cr_return_amount,
        wr.wr_return_amt,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_company = 2
      AND cd.cd_purchase_estimate >= 6000
      AND i.i_current_price > 30
      AND cs.cs_quantity > 2
      AND cr.cr_fee > 20.0
      AND wr.wr_return_quantity = 1
      AND EXISTS (
          SELECT 1
          FROM web_returns wr_exists
          WHERE wr_exists.wr_item_sk = cs.cs_item_sk
      )
)
SELECT
    cc_company,
    i_brand,
    cd_gender,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    SUM(cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM filtered_data
GROUP BY ROLLUP (cc_company, i_brand, cd_gender)
ORDER BY total_net_paid DESC
LIMIT 100
