WITH max_price AS (
    SELECT MAX(i_current_price) AS max_price
    FROM tpcds.item
),
joined AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        t.t_shift,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_city,
        cr.cr_return_amount,
        sr.sr_return_amt,
        CASE WHEN i.i_current_price > (SELECT max_price FROM max_price)
            THEN 'Above Max' ELSE 'Below Max' END AS price_flag,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_return_amt DESC) AS rn
    FROM tpcds.store s
    RIGHT OUTER JOIN tpcds.store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        s.s_state = 'TX'
        AND t.t_shift = 'first'
        AND cd.cd_gender = 'F'
        AND i.i_current_price BETWEEN 10 AND 1000
        AND cr.cr_return_amt_inc_tax > 100
        AND sr.sr_return_amt IS NOT NULL
)
SELECT *
FROM joined
WHERE rn <= 10
ORDER BY s_store_id, rn
LIMIT 100
