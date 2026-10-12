WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
order_diff AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
    EXCEPT
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year = 2001
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    r.r_reason_desc,
    d_cs.d_date      AS catalog_sale_date,
    d_ws.d_date      AS web_sale_date,
    d_sr.d_date      AS store_return_date,
    cs.cs_net_paid,
    ws.ws_net_paid,
    sr.sr_return_amt,
    inv_agg.total_qty_on_hand,
    RANK() OVER (
        PARTITION BY c.c_customer_id
        ORDER BY (cs.cs_net_paid + ws.ws_net_paid - sr.sr_return_amt) DESC
    ) AS customer_sales_rank,
    CASE
        WHEN ib.ib_upper_bound > 60000 THEN 'High Income'
        ELSE 'Other'
    END AS income_category
FROM catalog_sales cs
JOIN date_dim d_cs         ON cs.cs_sold_date_sk   = d_cs.d_date_sk
JOIN time_dim t_cs         ON cs.cs_sold_time_sk   = t_cs.t_time_sk
JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cs        ON cs.cs_warehouse_sk   = w_cs.w_warehouse_sk
JOIN item i                ON cs.cs_item_sk        = i.i_item_sk
JOIN customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca   ON cs.cs_bill_addr_sk   = ca.ca_address_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inv_agg          ON inv_agg.inv_item_sk = i.i_item_sk
                         AND inv_agg.inv_warehouse_sk = w_cs.w_warehouse_sk
-- Web sales side
JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws         ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws         ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN warehouse w_ws        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- Store returns side
JOIN store_returns sr      ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr         ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr         ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s               ON sr.sr_store_sk = s.s_store_sk
JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
WHERE d_cs.d_year = 2001
  AND d_ws.d_year = 2001
  AND d_sr.d_year = 2001
  AND i.i_current_price > 100
  AND s.s_state = 'CA'
  AND r.r_reason_desc LIKE '%damaged%'
  AND ib.ib_upper_bound > 60000
  AND ws.ws_order_number IN (SELECT ws_order_number FROM order_diff)
  AND cp.cp_department = 'Electronics'
LIMIT 100
