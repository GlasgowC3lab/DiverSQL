WITH ss_base AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_net_paid,
            c.c_customer_id,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            ca.ca_state,
            d.d_year,
            i.i_item_id,
            i.i_current_price,
            inv.inv_quantity_on_hand,
            w.w_warehouse_name,
            cp.cp_catalog_page_number,
            cp.cp_type
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    ),
    ws_base AS (
        SELECT
            ws.web_site_id,
            ws.web_name,
            ws.web_gmt_offset,
            d2.d_date_sk,
            d2.d_year AS ws_year,
            d2.d_month_seq
        FROM web_site ws
        JOIN date_dim d2 ON ws.web_open_date_sk = d2.d_date_sk
    ),
    grp AS (
        SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
    )
SELECT
    COALESCE(ss.ss_ticket_number, -1) AS ticket_number,
    ss.c_customer_id,
    ss.d_year,
    ss.i_item_id,
    ss.i_current_price,
    ss.inv_quantity_on_hand,
    ss.w_warehouse_name,
    ss.cp_catalog_page_number,
    ss.cp_type,
    ws.web_site_id,
    ws.web_name,
    ws.web_gmt_offset,
    g.grp,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.ss_net_paid DESC) AS sales_rank,
    CASE WHEN ss.ib_upper_bound > 150000 THEN 'HIGH_INCOME' ELSE 'MID_INCOME' END AS income_category
FROM ss_base ss
CROSS JOIN grp g
FULL OUTER JOIN ws_base ws ON ss.ss_sold_date_sk = ws.d_date_sk
WHERE
    ss.c_customer_id IS NOT NULL
    AND ss.d_year BETWEEN 1998 AND 2000
    AND ss.i_current_price > 20
    AND ss.inv_quantity_on_hand > 0
    AND ss.cp_type IN ('monthly', 'quarterly')
    AND ws.web_gmt_offset BETWEEN -5 AND 5
    AND g.grp <> 0
GROUP BY
    ss.c_customer_id,
    ss.d_year,
    ss.i_item_id,
    ss.i_current_price,
    ss.inv_quantity_on_hand,
    ss.w_warehouse_name,
    ss.cp_catalog_page_number,
    ss.cp_type,
    ws.web_site_id,
    ws.web_name,
    ws.web_gmt_offset,
    g.grp,
    ss.ss_net_paid,
    ss.ib_upper_bound,
    ss.ss_ticket_number
HAVING
    SUM(ss.ss_net_paid) > 1000
ORDER BY
    ss.d_year,
    sales_rank
