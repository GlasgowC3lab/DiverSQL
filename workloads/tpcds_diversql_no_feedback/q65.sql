WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year               AS sold_year,
        d_ship.d_year               AS ship_year,
        d_ship.d_date_sk            AS ship_date_sk,
        t.t_hour,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_state,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        sm.sm_type,
        w.w_warehouse_name,
        cp.cp_department,
        cp.cp_type,
        i.i_item_sk                 AS item_sk
    FROM catalog_sales cs
    FULL OUTER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        d_sold.d_year BETWEEN 2001 AND 2002
        AND i.i_current_price > 100.00
        AND sm.sm_type = 'AIR'
        AND ca.ca_state = 'CA'
        AND cp.cp_department = 'Electronics'
        AND cs.cs_quantity >= 2
)
SELECT
    se.sold_year,
    se.i_category,
    se.ca_state,
    se.cp_department,
    SUM(se.cs_ext_sales_price)        AS total_sales,
    SUM(se.cs_net_profit)             AS total_profit,
    COUNT(DISTINCT se.cs_order_number) AS distinct_orders,
    AVG(se.cs_quantity)               AS avg_quantity,
    MAX(wr.wr_return_amt)             AS max_return_amount,
    SUM(CASE WHEN wr.wr_return_amt IS NOT NULL THEN 1 ELSE 0 END) AS return_count,
    s.s_store_name
FROM sales_enriched se
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = se.item_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store s
    ON se.ship_date_sk = s.s_closed_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = se.item_sk
      AND wr2.wr_return_amt > 500.00
)
GROUP BY
    se.sold_year,
    se.i_category,
    se.ca_state,
    se.cp_department,
    s.s_store_name
ORDER BY total_sales DESC
LIMIT 100
