/* goal: Summarize combined store and web sales performance by store, web site, ship mode, year and product category, showing subtotals and a grand total. */
WITH base AS (
    SELECT
        s.s_store_name,
        wsite.web_name,
        sm.sm_type,
        d.d_year,
        i.i_category,
        ss.ss_ticket_number,
        ws.ws_order_number,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        ss.ss_net_profit,
        ws.ws_net_profit,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca_store_addr ON ss.ss_addr_sk = ca_store_addr.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
    
    JOIN customer_address ca_bill_addr ON ws.ws_bill_addr_sk = ca_bill_addr.ca_address_sk
    JOIN customer_address ca_ship_addr ON ws.ws_ship_addr_sk = ca_ship_addr.ca_address_sk
    
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
    
    JOIN customer_address ca_refund_addr ON wr.wr_refunded_addr_sk = ca_refund_addr.ca_address_sk
    JOIN customer_address ca_return_addr ON wr.wr_returning_addr_sk = ca_return_addr.ca_address_sk
    
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    
    /* additional optional filters using the same date_dim */
    WHERE i.i_current_price > (
            SELECT max(i2.i_current_price)
            FROM item i2
            WHERE i2.i_brand = 'Brand 1'
        )
      AND wp.wp_type = 'welcome'
      AND s.s_closed_date_sk = d.d_date_sk
      AND wsite.web_open_date_sk = d.d_date_sk
)
SELECT
    s_store_name,
    web_name,
    sm_type,
    d_year,
    i_category,
    COUNT(DISTINCT ss_ticket_number) AS store_sales_txns,
    COUNT(DISTINCT ws_order_number) AS web_sales_txns,
    SUM(COALESCE(ss_ext_sales_price, 0)) AS store_sales_amount,
    SUM(COALESCE(ws_ext_sales_price, 0)) AS web_sales_amount,
    SUM(COALESCE(wr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(wr_net_loss, 0)) AS net_profit
FROM base
GROUP BY ROLLUP (s_store_name, web_name, sm_type, d_year, i_category)
ORDER BY net_profit DESC
LIMIT 100
