WITH filtered_catalog_sales AS (
    SELECT cs.*
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
    )
    AND cs.cs_sold_date_sk IN (
        SELECT ss_sold_date_sk
        FROM store_sales
        WHERE ss_quantity > 5
    )
)
SELECT
    cs.cs_item_sk,
    i.i_product_name,
    SUM(cs.cs_ext_sales_price)            AS total_sales,
    AVG(cs.cs_ext_discount_amt)           AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number)    AS order_cnt,
    MIN(cs.cs_net_paid)                   AS min_net_paid,
    MAX(cs.cs_net_paid)                   AS max_net_paid,
    COUNT(*) FILTER (WHERE cr.cr_return_quantity > 0) AS return_qty_cnt
FROM filtered_catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_income
    ON hd_bill.hd_income_band_sk = hd_income.hd_demo_sk
JOIN income_band ib
    ON hd_income.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND i.i_current_price BETWEEN 10 AND 100
    AND p.p_discount_active = 'Y'
    AND ca_bill.ca_country = 'United States'
GROUP BY
    cs.cs_item_sk,
    i.i_product_name
ORDER BY
    total_sales DESC
LIMIT 100
