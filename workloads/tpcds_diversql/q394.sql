WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_returned_time_sk > 60000               -- filter 1: later part of day
      AND cr_reversed_charge < 500.00               -- filter 2: small reversal amounts
    GROUP BY cr_call_center_sk, cr_reason_sk
),
common_customers AS (
    SELECT cr_returning_customer_sk AS cust_sk
    FROM catalog_returns
    WHERE cr_return_amount > 1000
    INTERSECT
    SELECT wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_amt > 500
),
filtered AS (
    SELECT
        ca_agg.total_return_amount,
        ca_agg.cnt_returns,
        cc.cc_name,
        cc.cc_state,
        r.r_reason_desc,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca_addr.ca_address_sk,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        wp.wp_web_page_sk,
        wp.wp_url,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        wsit.web_name,
        wr.wr_return_amt
    FROM cr_agg ca_agg
    JOIN catalog_returns cr
        ON ca_agg.cr_call_center_sk = cr.cr_call_center_sk
       AND ca_agg.cr_reason_sk = cr.cr_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca_addr
        ON cr.cr_returning_addr_sk = ca_addr.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE c.c_customer_sk IN (SELECT cust_sk FROM common_customers)               -- filter 3: only customers appearing in both return streams
      AND cc.cc_state = 'CA'                                                    -- filter 4: call centers in California
      AND r.r_reason_desc LIKE '%defect%'                                      -- filter 5: specific return reason
      AND ws.ws_net_paid_inc_tax > 5000                                         -- filter 6: high‑value sales
)
SELECT
    cc_name,
    c_customer_id,
    c_first_name,
    c_last_name,
    r_reason_desc,
    total_return_amount,
    cnt_returns,
    ws_quantity,
    ws_net_paid,
    web_name,
    wp_url,
    (SELECT AVG(total_return_amount) FROM cr_agg) AS avg_return_amount,
    wr_return_amt
FROM filtered
ORDER BY cc_name
LIMIT 100
