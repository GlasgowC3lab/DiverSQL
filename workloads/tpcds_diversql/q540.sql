WITH
    full_cc_cr AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_call_center_sk AS cr_cc_sk
        FROM call_center cc
        FULL OUTER JOIN catalog_returns cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
    ),
    intersect_cust AS (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_birth_year = 1975
        INTERSECT
        SELECT cr.cr_refunded_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 200
    ),
    base AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sales_price,
            ss.ss_net_paid,
            ss.ss_quantity,
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_preferred_cust_flag,
            cd.cd_credit_rating,
            cd.cd_dep_count,
            hd.hd_buy_potential,
            ca.ca_state,
            ca.ca_city,
            ca.ca_address_sk
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
          AND c.c_preferred_cust_flag = 'Y'
          AND cd.cd_credit_rating = 'Good'
          AND hd.hd_buy_potential = 'High'
          AND ca.ca_state = 'CA'
    ),
    cr_join AS (
        SELECT
            b.*,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_call_center_sk
        FROM base b
        LEFT JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = b.c_customer_sk
           AND cr.cr_return_amount > 0
    ),
    wp_join AS (
        SELECT
            cj.*,
            wp.wp_max_ad_count,
            wp.wp_link_count,
            fcc.cc_name
        FROM cr_join cj
        LEFT JOIN web_page wp
            ON wp.wp_customer_sk = cj.c_customer_sk
           AND wp.wp_type = 'content'
        LEFT JOIN full_cc_cr fcc
            ON cj.cr_call_center_sk = fcc.cc_call_center_sk
        WHERE EXISTS (
            SELECT 1 FROM web_page wp2
            WHERE wp2.wp_customer_sk = cj.c_customer_sk
              AND wp2.wp_max_ad_count > 2
        )
    ),
    cross_set AS (
        SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    final_union AS (
        SELECT
            w.c_customer_sk,
            w.c_first_name,
            w.c_last_name,
            w.ca_city,
            w.ca_state,
            w.ss_sales_price,
            w.ss_net_paid,
            w.cr_return_quantity,
            w.cr_return_amount,
            w.wp_max_ad_count,
            w.wp_link_count,
            w.cc_name,
            (SELECT SUM(cr3.cr_return_amount)
               FROM catalog_returns cr3
               WHERE cr3.cr_refunded_customer_sk = w.c_customer_sk) AS total_refund_amount,
            (SELECT AVG(cr3.cr_return_amount)
               FROM catalog_returns cr3
               WHERE cr3.cr_refunded_customer_sk = w.c_customer_sk) AS avg_refund_amount,
            cs.dummy
        FROM wp_join w
        CROSS JOIN cross_set cs
        UNION
        SELECT
            b.c_customer_sk,
            b.c_first_name,
            b.c_last_name,
            b.ca_city,
            b.ca_state,
            b.ss_sales_price,
            b.ss_net_paid,
            NULL AS cr_return_quantity,
            NULL AS cr_return_amount,
            NULL AS wp_max_ad_count,
            NULL AS wp_link_count,
            NULL AS cc_name,
            (SELECT SUM(cr3.cr_return_amount)
               FROM catalog_returns cr3
               WHERE cr3.cr_refunded_customer_sk = b.c_customer_sk) AS total_refund_amount,
            (SELECT AVG(cr3.cr_return_amount)
               FROM catalog_returns cr3
               WHERE cr3.cr_refunded_customer_sk = b.c_customer_sk) AS avg_refund_amount,
            cs.dummy
        FROM base b
        CROSS JOIN cross_set cs
    )
SELECT
    fu.c_customer_sk,
    fu.c_first_name,
    fu.c_last_name,
    fu.ca_city,
    fu.ca_state,
    COUNT(*) AS transaction_cnt,
    SUM(fu.ss_sales_price) AS total_sales_price,
    AVG(fu.ss_net_paid) AS avg_net_paid,
    SUM(COALESCE(fu.cr_return_amount, 0)) AS total_return_amount,
    MAX(fu.total_refund_amount) AS max_total_refund,
    MIN(fu.avg_refund_amount) AS min_avg_refund,
    SUM(COALESCE(fu.wp_max_ad_count, 0)) AS sum_max_ad_count
FROM final_union fu
WHERE fu.c_customer_sk IN (SELECT c_customer_sk FROM intersect_cust)
GROUP BY
    fu.c_customer_sk,
    fu.c_first_name,
    fu.c_last_name,
    fu.ca_city,
    fu.ca_state
ORDER BY total_sales_price DESC
LIMIT 100
