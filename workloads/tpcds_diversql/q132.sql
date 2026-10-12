WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                             AND cr.cr_item_sk = i.i_item_sk
                             AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                       AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_paid > 1000
      AND cd.cd_gender = 'M'
      AND cc.cc_state = 'CA'
    GROUP BY d.d_year, i.i_category, cd.cd_gender
)
SELECT
    sa.d_year,
    sa.i_category,
    sa.total_net_paid,
    AVG(sa.total_net_paid) OVER (PARTITION BY sa.i_category) AS avg_total_net_paid_per_category,
    sa.total_returns,
    sa.orders,
    (SELECT COUNT(*) FROM call_center WHERE cc_state = 'CA') AS ca_call_center_count
FROM sales_agg sa
ORDER BY sa.total_net_paid DESC
LIMIT 100
