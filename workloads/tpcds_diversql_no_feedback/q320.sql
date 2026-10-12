WITH max_year AS (
    SELECT MAX(d_year) AS yr
    FROM tpcds.date_dim
),
sales_data AS (
    SELECT
        d.d_year,
        CASE 
            WHEN cs.cs_order_number IS NOT NULL THEN 'Catalog'
            WHEN ss.ss_ticket_number IS NOT NULL THEN 'Store'
            WHEN ws.ws_order_number IS NOT NULL THEN 'Web'
            ELSE 'Other'
        END AS sales_channel,
        COALESCE(cs.cs_ext_sales_price, 0) AS cs_sales,
        COALESCE(cs.cs_net_profit, 0)      AS cs_profit,
        COALESCE(ss.ss_ext_sales_price, 0) AS ss_sales,
        COALESCE(ss.ss_net_profit, 0)      AS ss_profit,
        COALESCE(ws.ws_ext_sales_price, 0) AS ws_sales,
        COALESCE(ws.ws_net_profit, 0)      AS ws_profit,
        i.i_color,
        p.p_discount_active
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_sales   ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales    ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i ON i.i_item_sk = COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk)
    LEFT JOIN tpcds.promotion p ON p.p_promo_sk = COALESCE(cs.cs_promo_sk, ss.ss_promo_sk, ws.ws_promo_sk)
    LEFT JOIN tpcds.warehouse w ON w.w_warehouse_sk = COALESCE(cs.cs_warehouse_sk, ws.ws_warehouse_sk)
    LEFT JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = COALESCE(cs.cs_ship_mode_sk, ws.ws_ship_mode_sk)
    LEFT JOIN tpcds.call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN tpcds.catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN tpcds.store s ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN tpcds.web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN tpcds.web_site we ON we.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                 AND inv.inv_date_sk = d.d_date_sk
)
SELECT
    d_year,
    sales_channel,
    SUM(cs_sales + ss_sales + ws_sales) AS total_sales,
    SUM(cs_profit + ss_profit + ws_profit) AS total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_sales + ss_sales + ws_sales) DESC) AS sales_rank,
    CASE WHEN d_year = (SELECT yr FROM max_year) THEN 'Current Year' ELSE 'Past Year' END AS year_category,
    (SELECT COUNT(*) FROM tpcds.store s2 WHERE s2.s_floor_space > 5000000) AS large_store_count
FROM sales_data
WHERE d_year BETWEEN 1999 AND 2001
  AND i_color IN ('Red', 'Blue')
  AND p_discount_active = 'Y'
GROUP BY GROUPING SETS (
    (d_year, sales_channel),
    (d_year)
)
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
