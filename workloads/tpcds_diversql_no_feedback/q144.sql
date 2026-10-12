WITH cat_orders AS (
   SELECT cs.cs_order_number AS order_number
   FROM catalog_sales cs
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   WHERE cr.cr_return_amount > 0
),
web_orders AS (
   SELECT ws.ws_order_number AS order_number
   FROM web_sales ws
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   WHERE wr.wr_return_amt > 0
),
common_orders AS (
   SELECT order_number FROM cat_orders
   INTERSECT
   SELECT order_number FROM web_orders
)
SELECT d1.d_year,
       i.i_category,
       SUM(cs.cs_net_paid)                         AS total_net_paid,
       COUNT(DISTINCT cs.cs_order_number)           AS num_catalog_orders,
       COUNT(DISTINCT ws.ws_order_number)           AS num_web_orders,
       COUNT(DISTINCT cr.cr_reason_sk)              AS distinct_return_reasons
FROM common_orders co
JOIN catalog_sales cs            ON cs.cs_order_number = co.order_number
JOIN web_sales ws                ON ws.ws_order_number = co.order_number
JOIN date_dim d1                 ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN date_dim d2                 ON ws.ws_sold_date_sk = d2.d_date_sk
JOIN item i                      ON cs.cs_item_sk = i.i_item_sk
JOIN customer c                  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd   ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib              ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w                 ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss              ON ss.ss_sold_date_sk = d1.d_date_sk
                                 AND ss.ss_item_sk = i.i_item_sk
                                 AND ss.ss_customer_sk = c.c_customer_sk
JOIN web_site site               ON ws.ws_web_site_sk = site.web_site_sk
JOIN catalog_returns cr          ON cr.cr_order_number = cs.cs_order_number
JOIN reason r_cat                ON cr.cr_reason_sk = r_cat.r_reason_sk
JOIN web_returns wr              ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_web                ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 0
    )
GROUP BY d1.d_year, i.i_category
ORDER BY total_net_paid DESC
LIMIT 100
