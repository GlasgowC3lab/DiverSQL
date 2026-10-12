WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 1000
      AND p.p_discount_active = 'Y'
),

order_intersect AS (
    SELECT cs_order_number AS order_num
    FROM cs_base
    WHERE cs_net_profit > 500
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND cr.cr_net_loss > 100
),

extended_sales AS (
    SELECT
        b.*,
        cr.cr_reason_sk,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        ss.ss_net_paid,
        wp.wp_url
    FROM cs_base b
    LEFT JOIN catalog_returns cr
        ON b.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON b.cs_sold_date_sk = inv.inv_date_sk
        AND b.cs_item_sk = inv.inv_item_sk
    LEFT JOIN store_sales ss
        ON b.cs_sold_date_sk = ss.ss_sold_date_sk
        AND b.cs_item_sk = ss.ss_item_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = b.cs_sold_date_sk
           OR wp.wp_access_date_sk = b.cs_sold_date_sk
    WHERE b.cs_order_number IN (SELECT order_num FROM order_intersect)
),

ranked_sales AS (
    SELECT
        es.cs_order_number,
        es.cp_department,
        es.cs_ext_sales_price,
        es.cs_net_profit,
        es.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY es.cp_department ORDER BY es.cs_net_profit DESC) AS rn,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2001
           AND cs2.cs_catalog_page_sk = es.cs_catalog_page_sk) AS dept_avg_profit,
        es.ca_city,
        es.ca_state,
        es.ca_country,
        es.p_promo_name,
        es.cc_name,
        es.r_reason_desc,
        es.inv_quantity_on_hand,
        es.ss_net_paid,
        es.wp_url
    FROM extended_sales es
)

SELECT
    rs.cs_order_number,
    rs.cp_department,
    rs.cs_ext_sales_price,
    rs.cs_net_profit,
    rs.dept_avg_profit,
    rs.rn,
    rs.ca_city,
    rs.ca_state,
    rs.ca_country,
    rs.p_promo_name,
    rs.cc_name,
    rs.r_reason_desc,
    rs.inv_quantity_on_hand,
    rs.ss_net_paid,
    rs.wp_url
FROM ranked_sales rs
WHERE rs.rn <= 5
ORDER BY rs.cp_department, rs.rn
LIMIT 100
