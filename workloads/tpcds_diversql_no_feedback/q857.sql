WITH sales_summary AS (
    SELECT
        cs.cs_order_number,
        d.d_year,
        i.i_category,
        w.w_state,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS line_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_warehouse_sk = w.w_warehouse_sk
                           AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                           AND wp.wp_creation_date_sk = cs.cs_sold_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Electronics'
      AND w.w_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cc.cc_company_name = 'PC Catalog'
    GROUP BY cs.cs_order_number, d.d_year, i.i_category, w.w_state
)
SELECT
    s.d_year,
    s.i_category,
    SUM(s.total_paid) AS year_category_total,
    AVG(s.total_paid) AS avg_order_total,
    COUNT(DISTINCT s.cs_order_number) AS orders_cnt
FROM sales_summary s
WHERE s.cs_order_number NOT IN (
    SELECT cr_sub.cr_order_number
    FROM catalog_returns cr_sub
    WHERE cr_sub.cr_return_quantity > 0
)
GROUP BY s.d_year, s.i_category
HAVING AVG(s.total_paid) > 1000
ORDER BY year_category_total DESC
LIMIT 100
