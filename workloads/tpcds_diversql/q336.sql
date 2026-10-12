WITH inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    d1.d_date                         AS sale_date,
    cs.cs_order_number               AS order_number,
    cs.cs_ext_sales_price            AS ext_sales_price,
    RANK() OVER (PARTITION BY d1.d_year ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
    (
        SELECT AVG(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = d1.d_date_sk
    )                                 AS avg_quantity_by_date,
    i.inv_quantity_on_hand           AS inventory_on_hand,
    we.web_name                      AS website_name,
    r.r_reason_desc                  AS return_reason,
    sm.sm_code                       AS ship_mode_code,
    cp.cp_department                 AS catalog_department
FROM catalog_sales cs
INNER JOIN date_dim d1
        ON cs.cs_sold_date_sk = d1.d_date_sk
INNER JOIN time_dim t1
        ON cs.cs_sold_time_sk = t1.t_time_sk
INNER JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN inventory_sample i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d1.d_date_sk
LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN customer c_sr_cust
        ON sr.sr_customer_sk = c_sr_cust.c_customer_sk
LEFT JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
INNER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
        AND ws.ws_sold_time_sk = t1.t_time_sk
        AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
INNER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d1.d_date_sk
        AND wr.wr_returned_time_sk = t1.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
WHERE d1.d_year = 2001
  AND cp.cp_department = 'Books'
  AND sm.sm_code = 'AIR'
  AND cs.cs_quantity > 2
  AND cs.cs_order_number IN (
        (SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 3)
        INTERSECT
        (SELECT ws_order_number FROM web_sales WHERE ws_quantity > 3)
    )
ORDER BY sales_rank, cs.cs_ext_sales_price DESC
OFFSET 0 LIMIT 100
