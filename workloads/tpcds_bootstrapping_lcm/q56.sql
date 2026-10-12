SELECT
    cp.cp_department,
    cp.cp_description,
    cp.cp_type,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    s.s_store_name,
    s.s_state,
    s.s_number_employees,
    s.s_company_id,
    CASE 
        WHEN ws.ws_sales_price <> 0 THEN ws.ws_net_profit / ws.ws_sales_price 
        ELSE NULL 
    END AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM catalog_page cp
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
CROSS JOIN date_dim d_wp_creation
JOIN web_page wp ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_sales ws ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
CROSS JOIN date_dim d_store_closed
JOIN store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
ORDER BY cp.cp_department, profit_rank
LIMIT 100
