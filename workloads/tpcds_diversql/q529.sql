WITH sales_agg AS (
    SELECT
        s.s_store_name,
        wsite.web_name,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers,
        MIN(d_sales.d_date) AS min_sales_date,
        MAX(d_sales.d_date) AS max_sales_date,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ss.ss_ticket_number = ws.ws_order_number
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND s.s_tax_percentage > 0.05
        AND c.c_birth_month = 3
        AND i.i_color = 'Red'
        AND wsite.web_open_date_sk = (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001
        )
        AND ss.ss_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_brand = 'Brand#12'
        )
    GROUP BY s.s_store_name, wsite.web_name
),
intersect_orders AS (
    SELECT ws.ws_order_number AS order_no FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    INTERSECT
    SELECT wr.wr_order_number FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
ranked_items AS (
    SELECT
        i.i_item_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_quantity) DESC) AS item_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY i.i_item_id, s.s_store_name
    HAVING SUM(ss.ss_quantity) > 0
),
cross_join_set AS (
    SELECT v.multiplier, d.d_date
    FROM (VALUES 1, 2, 3) AS v(multiplier)
    CROSS JOIN (
        SELECT d_date FROM date_dim d WHERE d.d_year = 2001 LIMIT 3
    ) AS d
)
SELECT DISTINCT
    sa.s_store_name,
    sa.web_name,
    sa.store_net_paid,
    sa.web_net_paid,
    sa.distinct_store_customers,
    sa.distinct_web_customers,
    sa.min_sales_date,
    sa.max_sales_date,
    sa.total_inventory_on_hand,
    io.order_no,
    ri.item_rank,
    ccr.cc_name,
    cp.cp_department,
    rs.r_reason_desc,
    cs.multiplier,
    cs.d_date
FROM sales_agg sa
CROSS JOIN intersect_orders io
JOIN ranked_items ri ON ri.s_store_name = sa.s_store_name
JOIN web_returns wr ON wr.wr_order_number = io.order_no
JOIN reason rs ON wr.wr_reason_sk = rs.r_reason_sk
JOIN call_center ccr ON ccr.cc_closed_date_sk = (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 1
)
JOIN catalog_page cp ON cp.cp_start_date_sk = (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 1
)
CROSS JOIN cross_join_set cs
ORDER BY sa.store_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
