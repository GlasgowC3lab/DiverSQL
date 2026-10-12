WITH diff_orders AS (
       SELECT cs.cs_order_number
       FROM catalog_sales cs
       EXCEPT
       SELECT ws.ws_order_number
       FROM web_sales ws
   ),
   base AS (
       SELECT
           w.w_state,
           p.p_promo_name,
           d_sold.d_year,
           SUM(cs.cs_net_paid)                               AS total_catalog_sales,
           SUM(ws.ws_net_paid)                               AS total_web_sales,
           SUM(ss.ss_net_paid)                               AS total_store_sales,
           SUM(wr.wr_net_loss)                               AS total_web_returns_loss,
           SUM(inv.inv_quantity_on_hand)                     AS total_inventory_qty,
           -- correlated scalar sub‑query per department
           (SELECT COUNT(*)
            FROM catalog_page cp2
            WHERE cp2.cp_department = cp.cp_department)   AS dept_page_cnt
       FROM catalog_sales cs
       JOIN diff_orders do ON cs.cs_order_number = do.cs_order_number
       JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk               -- join rule 1
       JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk               -- join rule 2
       JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk     -- join rule 3
       JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk                         -- join rule 4
       JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk               -- join rule 5
       JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk                 -- join rule 6
       LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk   -- join rule 7
       LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
                                 AND ws.ws_warehouse_sk = w.w_warehouse_sk   -- join rule 8
       LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk          -- join rule 9
       LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_returned_date_sk = d_sold.d_date_sk   -- join rule 10
       LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk                      -- join rule 11
       JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk    -- join rule 12
       JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk -- join rule 13
       GROUP BY w.w_state, p.p_promo_name, d_sold.d_year, cp.cp_department
   )
SELECT
    b.w_state,
    b.p_promo_name,
    b.d_year,
    b.total_catalog_sales,
    b.total_web_sales,
    b.total_store_sales,
    b.total_web_returns_loss,
    b.total_inventory_qty,
    b.dept_page_cnt,
    -- running total of catalog sales per state ordered by year
    SUM(b.total_catalog_sales) OVER (PARTITION BY b.w_state ORDER BY b.d_year
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_catalog_sales
FROM base b
WHERE b.total_catalog_sales > 100000                                   -- HAVING‑like filter after aggregation
ORDER BY b.w_state, b.d_year DESC
LIMIT 100
