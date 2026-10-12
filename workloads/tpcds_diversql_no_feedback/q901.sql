WITH joined AS (
   SELECT
       d.d_year,
       cp.cp_department,
       sm.sm_type,
       cs.cs_ext_sales_price,
       ws.ws_ext_sales_price,
       cr.cr_return_amount,
       cs.cs_wholesale_cost,
       ws.ws_net_paid,
       cr.cr_return_quantity
   FROM tpcds.date_dim d
   RIGHT OUTER JOIN tpcds.store_sales ss
       ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN tpcds.catalog_sales cs
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.catalog_returns cr
       ON cr.cr_item_sk = cs.cs_item_sk
      AND cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.web_sales ws
       ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE
       d.d_year = 2001
       AND cp.cp_type = 'REGULAR'
       AND sm.sm_type = 'EXPRESS'
       AND cs.cs_wholesale_cost > 50
       AND ws.ws_net_paid > 1000
       AND cr.cr_return_quantity > 0
       AND EXISTS (
           SELECT 1 FROM tpcds.catalog_returns cr2
           WHERE cr2.cr_order_number = cs.cs_order_number
             AND cr2.cr_return_amount > 0
       )
),
agg AS (
   SELECT
       d_year,
       cp_department,
       sm_type,
       SUM(COALESCE(cs_ext_sales_price, 0) + COALESCE(ws_ext_sales_price, 0) - COALESCE(cr_return_amount, 0)) AS total_sales
   FROM joined
   GROUP BY d_year, cp_department, sm_type
)
SELECT
   d_year,
   cp_department,
   sm_type,
   total_sales,
   rank
FROM (
   SELECT
       d_year,
       cp_department,
       sm_type,
       total_sales,
       ROW_NUMBER() OVER (PARTITION BY d_year, cp_department ORDER BY total_sales DESC) AS rank
   FROM agg
   WHERE total_sales > 0
) t
WHERE rank <= 3
ORDER BY d_year, cp_department, rank
