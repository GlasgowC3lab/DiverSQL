WITH
  base AS (
    SELECT *
    FROM time_dim
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of the time dimension
  ),
  sales_join AS (
    SELECT
      c.c_customer_id,
      SUM(ss.ss_ext_sales_price)        AS store_sales_total,
      SUM(cs.cs_ext_sales_price)        AS catalog_sales_total,
      SUM(ws.ws_ext_sales_price)        AS web_sales_total,
      COUNT(DISTINCT ss.ss_ticket_number)  AS store_txn_cnt,
      COUNT(DISTINCT cs.cs_order_number)   AS catalog_txn_cnt,
      COUNT(DISTINCT ws.ws_order_number)   AS web_txn_cnt
    FROM base t
    JOIN store_sales ss          ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c              ON ss.ss_customer_sk   = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk    = cd.cd_demo_sk
    JOIN customer_address ca      ON ss.ss_addr_sk      = ca.ca_address_sk
    JOIN catalog_sales cs        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p             ON cs.cs_promo_sk     = p.p_promo_sk
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr      ON cr.cr_returned_time_sk = t.t_time_sk
                                 AND cr.cr_order_number   = cs.cs_order_number
    JOIN store_returns sr        ON sr.sr_return_time_sk = t.t_time_sk
                                 AND sr.sr_ticket_number  = ss.ss_ticket_number
    JOIN reason r                ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws            ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr          ON wr.wr_returned_time_sk = t.t_time_sk
                                 AND wr.wr_order_number   = ws.ws_order_number
    WHERE t.t_hour BETWEEN 9 AND 17                               -- business hours
      AND c.c_birth_year BETWEEN 1960 AND 1980                     -- age filter
      AND ss.ss_quantity > 5                                      -- store sales quantity
      AND cs.cs_quantity > 2                                      -- catalog sales quantity
      AND ws.ws_quantity > 3                                      -- web sales quantity
      AND cp.cp_type = 'monthly'                                  -- catalog page type
      AND sm.sm_type = 'AIR'                                      -- ship mode type
      AND p.p_discount_active = 'Y'                               -- active promotions
    GROUP BY c.c_customer_id
  ),
  avg_total AS (
    SELECT AVG(store_sales_total + catalog_sales_total + web_sales_total) AS avg_customer_total
    FROM sales_join
  )
SELECT
  sj.c_customer_id,
  sj.store_sales_total,
  sj.catalog_sales_total,
  sj.web_sales_total,
  (sj.store_sales_total + sj.catalog_sales_total + sj.web_sales_total) AS total_sales,
  at.avg_customer_total
FROM sales_join sj
CROSS JOIN avg_total at
WHERE (sj.store_sales_total + sj.catalog_sales_total + sj.web_sales_total) > at.avg_customer_total * 1.5
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
