WITH sold_not_returned AS (
    SELECT DISTINCT i.i_item_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    EXCEPT
    SELECT DISTINCT i2.i_item_id
    FROM store_returns sr
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
)
SELECT
    c.c_customer_id,
    i.i_category,
    cc.cc_name,
    wp.wp_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(sr.sr_return_amt) AS total_return_amount,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_department = 'Electronics'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND ca.ca_zip = '85709'
    AND ib.ib_upper_bound <= 120000
    AND i.i_rec_start_date >= DATE '2001-01-01'
    AND i.i_item_id IN (SELECT i_item_id FROM sold_not_returned)
GROUP BY
    c.c_customer_id,
    i.i_category,
    cc.cc_name,
    wp.wp_type
ORDER BY total_net_paid DESC
LIMIT 100
