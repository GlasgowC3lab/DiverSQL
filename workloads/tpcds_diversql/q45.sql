WITH sampled_catalog_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    cc.cc_state,
    cp.cp_department,
    sm.sm_type,
    p.p_promo_name,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_tax) AS avg_ext_tax,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN sampled_catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'TX'
  AND cp.cp_catalog_number = 20
  AND inv.inv_quantity_on_hand > 500
  AND sm.sm_type = 'AIR'
  AND ss.ss_net_paid > (
        SELECT MAX(cs_net_paid) FROM catalog_sales
    )
GROUP BY d.d_year, cc.cc_state, cp.cp_department, sm.sm_type, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
