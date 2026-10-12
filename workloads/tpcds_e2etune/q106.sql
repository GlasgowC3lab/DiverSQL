WITH unified_returns AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cc.cc_manager AS manager,
        NULL AS page_type,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS quantity,
        cr.cr_order_number AS order_number,
        cr.cr_returned_date_sk AS returned_date_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_manager = 'Bob Belcher'
      AND cc.cc_employees > 2000000
      AND c.c_birth_year BETWEEN 1965 AND 1995
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910

    UNION ALL

    SELECT
        r.r_reason_desc AS reason_desc,
        NULL AS manager,
        wp.wp_type AS page_type,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS quantity,
        wr.wr_order_number AS order_number,
        wr.wr_returned_date_sk AS returned_date_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'content'
      AND c.c_birth_country = 'United States'
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
),
aggregated AS (
    SELECT
        reason_desc,
        manager,
        page_type,
        COUNT(DISTINCT order_number) AS distinct_orders,
        SUM(net_loss) AS total_net_loss,
        SUM(quantity) AS total_quantity
    FROM unified_returns
    GROUP BY
        reason_desc,
        manager,
        page_type
    HAVING
        SUM(net_loss) > 5000
)
SELECT
    reason_desc,
    manager,
    page_type,
    distinct_orders,
    total_net_loss,
    total_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
