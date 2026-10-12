WITH cat AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_order_number,
        cc.cc_name,
        cc.cc_state,
        cc.cc_rec_start_date,
        cc.cc_rec_end_date,
        i.i_brand,
        i.i_category,
        w.w_warehouse_name,
        w.w_state,
        td.t_hour,
        td.t_meal_time,
        ca.ca_county
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND i.i_brand = 'Brand#12'
        AND ca.ca_county = 'Madison County'
        AND td.t_hour BETWEEN 9 AND 17
        AND cc.cc_rec_start_date >= DATE '2001-01-01'
        AND cc.cc_rec_end_date <= DATE '2005-12-31'
)
SELECT
    cat.cc_name,
    cat.i_brand,
    cat.i_category,
    cat.w_warehouse_name,
    cat.t_hour,
    SUM(cat.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT cat.cs_order_number) AS distinct_orders,
    AVG(cat.cs_net_profit) AS avg_catalog_profit
FROM cat
JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = cat.cs_item_sk
    AND ss.ss_sold_time_sk = cat.cs_sold_time_sk
    AND ss.ss_addr_sk = cat.cs_bill_addr_sk
FULL OUTER JOIN tpcds.store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = cat.cs_item_sk
    AND inv.inv_warehouse_sk = cat.cs_warehouse_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = cat.cs_item_sk
    AND ws.ws_sold_time_sk = cat.cs_sold_time_sk
    AND ws.ws_bill_addr_sk = cat.cs_bill_addr_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_type = 'home'
    AND inv.inv_quantity_on_hand > 0
    AND ws.ws_ship_customer_sk > 1000000
    AND sr.sr_return_quantity IS NOT NULL
    AND cat.t_meal_time = 'Lunch'
GROUP BY
    cat.cc_name,
    cat.i_brand,
    cat.i_category,
    cat.w_warehouse_name,
    cat.t_hour
ORDER BY total_catalog_sales DESC
LIMIT 100
