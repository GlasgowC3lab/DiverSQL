WITH
    date_filter AS (
        SELECT d.*
        FROM date_dim d
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND d.d_month_seq IN (1, 2, 3, 4, 5)
          AND d.d_weekend = 'N'
    ),
    store_sales_right AS (
        SELECT ss.*, d.d_year, d.d_month_seq
        FROM store_sales ss
        RIGHT OUTER JOIN date_filter d
          ON ss.ss_sold_date_sk = d.d_date_sk
    ),
    intersect_items AS (
        SELECT i.i_item_id
        FROM item i
        JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
        WHERE ss.ss_quantity > 10
        INTERSECT
        SELECT i2.i_item_id
        FROM item i2
        JOIN catalog_sales cs ON i2.i_item_sk = cs.cs_item_sk
        WHERE cs.cs_quantity > 5
    ),
    sampled_inventory AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)   -- 10 percent sample
    )
SELECT
    d.d_year,
    i.i_category,
    ws.web_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_net_profit) AS avg_profit,
    MIN(ss.ss_sold_date_sk) AS min_sold_date_sk,
    MAX(ss.ss_sold_date_sk) AS max_sold_date_sk
FROM store_sales_right ss
JOIN date_filter d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN sampled_inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
 AND cs.cs_item_sk = i.i_item_sk
 AND cs.cs_bill_customer_sk = c.c_customer_sk
 AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
 AND cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_item_sk = i.i_item_sk
 AND wr.wr_refunded_customer_sk = c.c_customer_sk
 AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
 AND wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE
    i.i_class_id IN (4, 8, 15)
 AND cc.cc_manager = 'Larry Mccray'
 AND sm.sm_type = 'AIR'
 AND cp.cp_type = 'C'
 AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_quantity > 0
    )
 AND i.i_item_id IN (SELECT i_item_id FROM intersect_items)
GROUP BY
    d.d_year,
    i.i_category,
    ws.web_name
ORDER BY
    total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
