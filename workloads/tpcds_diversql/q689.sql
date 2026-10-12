WITH
    inv_sample AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    diff_orders AS (
        SELECT cs_order_number AS order_number FROM catalog_sales
        EXCEPT
        SELECT ws_order_number FROM web_sales
    ),
    joined AS (
        SELECT
            d.d_year,
            i.i_item_id,
            i.i_product_name,
            cs.cs_order_number,
            cs.cs_net_paid_inc_tax,
            ws.ws_order_number AS ws_order_number,
            ws.ws_net_paid_inc_tax,
            sm.sm_type,
            ca.ca_state,
            hd.hd_income_band_sk,
            cp.cp_department,
            reason.r_reason_desc,
            unnest_val,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_paid_inc_tax DESC) AS cs_rank,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_paid_inc_tax DESC) AS ws_rank,
            COUNT(DISTINCT cs.cs_order_number) OVER () AS distinct_cs_orders,
            COUNT(DISTINCT ws.ws_order_number) OVER () AS distinct_ws_orders
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN inv_sample inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
        JOIN reason ON cr.cr_reason_sk = reason.r_reason_sk
        CROSS JOIN UNNEST(ARRAY[reason.r_reason_id, reason.r_reason_desc]) AS t(unnest_val)
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
        WHERE d.d_year = 2001
          AND i.i_brand = 'Brand#12'
          AND sm.sm_type = 'AIR'
    )
SELECT
    j.d_year,
    j.i_item_id,
    j.i_product_name,
    j.cs_rank,
    j.ws_rank,
    j.unnest_val,
    j.distinct_cs_orders,
    j.distinct_ws_orders,
    CASE WHEN diff.order_number IS NOT NULL THEN 1 ELSE 0 END AS order_missing_in_web
FROM joined j
LEFT JOIN diff_orders diff ON j.cs_order_number = diff.order_number
ORDER BY j.d_year, j.cs_rank
LIMIT 100
