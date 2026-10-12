WITH
    cc_dates AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            d.d_date_sk
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    ),
    ws_dates AS (
        SELECT
            ws.web_site_sk,
            ws.web_name,
            ws.web_city,
            d.d_date_sk
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    ),
    full_dim AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            ws.web_site_sk,
            ws.web_name,
            ws.web_city
        FROM cc_dates cc
        FULL OUTER JOIN ws_dates ws USING (d_date_sk)
    ),
    base_fact AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            sr.sr_customer_sk,
            sr.sr_cdemo_sk,
            sr.sr_hdemo_sk,
            sr.sr_addr_sk,
            sr.sr_store_sk,
            sr.sr_reason_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_return_amt_inc_tax,
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_fee,
            cr.cr_ship_mode_sk,
            cr.cr_call_center_sk,
            d.d_year,
            d.d_date,
            i.i_category,
            i.i_brand,
            c.c_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            ca.ca_state,
            cd.cd_gender,
            hd.hd_buy_potential,
            sm.sm_type,
            sm.sm_carrier,
            rs.r_reason_desc,
            p.p_promo_name,
            wp.wp_type,
            ws.web_city
        FROM store_returns sr
        RIGHT OUTER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN store st ON sr.sr_store_sk = st.s_store_sk
        JOIN reason rs ON sr.sr_reason_sk = rs.r_reason_sk
        LEFT JOIN catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
            AND sr.sr_returned_date_sk = cr.cr_returned_date_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
            AND p.p_start_date_sk = d.d_date_sk
        LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    ),
    union_set AS (
        SELECT sr.sr_customer_sk AS cust_sk,
               SUM(sr.sr_return_amt) AS total_ret
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
        UNION
        SELECT cr.cr_refunded_customer_sk AS cust_sk,
               SUM(cr.cr_return_amount) AS total_ret
        FROM catalog_returns cr
        GROUP BY cr.cr_refunded_customer_sk
    ),
    intersect_cust AS (
        SELECT sr.sr_customer_sk AS cust_sk FROM store_returns sr
        INTERSECT
        SELECT cr.cr_refunded_customer_sk AS cust_sk FROM catalog_returns cr
    )
SELECT
    bf.c_customer_id,
    bf.c_first_name,
    bf.c_last_name,
    bf.d_year,
    bf.i_category,
    SUM(CASE WHEN bf.sm_type = 'OVERNIGHT' THEN bf.sr_return_amt ELSE 0 END) AS overnight_return_amt,
    COUNT(*) AS return_cnt,
    MIN(bf.sr_return_amt) AS min_return,
    MAX(bf.sr_return_amt) AS max_return,
    AVG(bf.sr_return_amt) AS avg_return
FROM base_fact bf
RIGHT OUTER JOIN store st ON bf.sr_store_sk = st.s_store_sk
WHERE bf.d_year = 2001
  AND bf.i_brand = 'Brand#12'
  AND bf.sm_carrier = 'UPS'
  AND bf.ca_state = 'CA'
  AND bf.web_city = 'Seattle'
  AND bf.c_customer_sk IN (SELECT cust_sk FROM intersect_cust)
GROUP BY
    bf.c_customer_id,
    bf.c_first_name,
    bf.c_last_name,
    bf.d_year,
    bf.i_category
HAVING SUM(bf.sr_return_amt) > 1000
ORDER BY overnight_return_amt DESC
LIMIT 100
