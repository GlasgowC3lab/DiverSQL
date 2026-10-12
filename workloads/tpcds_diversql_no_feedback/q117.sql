WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_item_sk
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    p.p_promo_name,
    cp.cp_department,
    ws.web_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                 AND wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                     AND ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND p.p_channel_email = 'N'
  AND cp.cp_department = 'Electronics'
  AND NOT EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
          AND inv2.inv_quantity_on_hand > 0
      )
GROUP BY d.d_year, p.p_promo_name, cp.cp_department, ws.web_name
ORDER BY total_net_paid DESC
LIMIT 100
