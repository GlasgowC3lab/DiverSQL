WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        ss.ss_ext_sales_price   AS ss_sales,
        ss.ss_quantity          AS ss_qty,
        ws.ws_ext_sales_price   AS ws_sales,
        ws.ws_quantity          AS ws_qty,
        cr.cr_return_amount,
        i.i_category,
        i.i_class,
        i.i_item_sk,
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        cc.cc_state,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        cust.c_customer_id,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i                   ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    JOIN customer cust            ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk   = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk      = cs.cs_item_sk
    LEFT JOIN store_sales ss      ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
                                 AND ss.ss_item_sk      = cs.cs_item_sk
    LEFT JOIN web_sales ws        ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
                                 AND ws.ws_item_sk      = cs.cs_item_sk
    LEFT JOIN inventory inv       ON inv.inv_item_sk    = cs.cs_item_sk
                                 AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
                                 AND inv.inv_date_sk   = cs.cs_sold_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND cc.cc_state = 'CA'
)
SELECT
    i_category,
    i_class,
    d_year,
    SUM(cs_ext_sales_price)        AS total_catalog_sales,
    SUM(ss_sales)                  AS total_store_sales,
    SUM(ws_sales)                  AS total_web_sales,
    SUM(cr_return_amount)          AS total_return_amount,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(cs_ext_sales_price) DESC) AS catalog_sales_rank,
    CASE WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_volume_label
FROM base
GROUP BY GROUPING SETS (
    (i_category, i_class, d_year),
    (i_category, d_year),
    (d_year)
)
ORDER BY total_catalog_sales DESC
LIMIT 100
