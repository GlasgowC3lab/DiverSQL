WITH recent_inventory AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        w.w_warehouse_name,
        c.c_customer_id,
        ca.ca_city,
        cs.cs_ext_sales_price        AS ext_sales_price,
        cs.cs_quantity               AS quantity,
        CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT SUM(ss2.ss_quantity)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = i.i_item_sk) AS total_store_qty,
        td.t_hour
    FROM catalog_sales cs
    JOIN time_dim td            ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk      = ca.ca_address_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk      = sm.sm_ship_mode_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk      = w.w_warehouse_sk
    JOIN item i                ON cs.cs_item_sk           = i.i_item_sk
    JOIN promotion p           ON cs.cs_promo_sk          = p.p_promo_sk
    JOIN recent_inventory ri   ON ri.inv_item_sk = i.i_item_sk AND ri.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
),
joined_data2 AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        w2.w_warehouse_name,
        c2.c_customer_id,
        ca2.ca_city,
        ws.ws_ext_sales_price       AS ext_sales_price,
        ws.ws_quantity              AS quantity,
        CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT SUM(ss2.ss_quantity)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = i.i_item_sk) AS total_store_qty,
        td2.t_hour
    FROM web_sales ws
    JOIN time_dim td2          ON ws.ws_sold_time_sk   = td2.t_time_sk
    JOIN customer c2           ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2  ON ws.ws_bill_addr_sk      = ca2.ca_address_sk
    JOIN web_page wp           ON ws.ws_web_page_sk   = wp.wp_web_page_sk
    JOIN ship_mode sm2         ON ws.ws_ship_mode_sk   = sm2.sm_ship_mode_sk
    JOIN warehouse w2          ON ws.ws_warehouse_sk   = w2.w_warehouse_sk
    JOIN item i                ON ws.ws_item_sk        = i.i_item_sk
    JOIN promotion p2          ON ws.ws_promo_sk       = p2.p_promo_sk
    JOIN recent_inventory ri2 ON ri2.inv_item_sk = i.i_item_sk AND ri2.inv_warehouse_sk = w2.w_warehouse_sk
)
SELECT
    i_item_id,
    i_brand,
    w_warehouse_name,
    c_customer_id,
    ca_city,
    SUM(ext_sales_price) AS total_ext_sales,
    SUM(quantity)        AS total_quantity,
    COUNT(DISTINCT sales_category) AS sales_category_count,
    SUM(total_store_qty) AS agg_store_qty,
    AVG(t_hour)          AS avg_hour
FROM (
    SELECT * FROM joined_data
    UNION DISTINCT
    SELECT * FROM joined_data2
) u
GROUP BY
    i_item_id,
    i_brand,
    w_warehouse_name,
    c_customer_id,
    ca_city
ORDER BY total_ext_sales DESC
LIMIT 100
