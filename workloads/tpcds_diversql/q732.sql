WITH
  main AS (
    SELECT
      cc.cc_name,
      s.s_store_name,
      d.d_year,
      SUM(cs.cs_net_paid_inc_ship)               AS total_sales,
      SUM(ss.ss_net_profit)                      AS total_store_profit,
      AVG(wr.wr_return_amt)                      AS avg_web_return,
      MIN(sr.sr_return_amt)                      AS min_store_return_amt,
      COUNT(DISTINCT i.i_item_id)                AS distinct_items,
      COUNT(DISTINCT cs.cs_order_number)         AS distinct_orders,
      COUNT(DISTINCT wp.wp_web_page_id)          AS distinct_web_pages,
      COUNT(DISTINCT ws.web_site_id)             AS distinct_web_sites
    FROM
      date_dim d
      JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
      JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
      JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
      JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
      d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cc.cc_state = 'CA'
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red')
      AND ss.ss_store_sk IN (SELECT s2.s_store_sk FROM store s2 WHERE s2.s_state = 'CA')
    GROUP BY
      cc.cc_name,
      s.s_store_name,
      d.d_year
  ),
  except_set AS (
    SELECT ss.ss_ticket_number AS ticket
    FROM store_sales ss
    EXCEPT
    SELECT sr.sr_ticket_number FROM store_returns sr
  ),
  intersect_set AS (
    SELECT cs.cs_order_number AS order_num
    FROM catalog_sales cs
    INTERSECT
    SELECT ss.ss_ticket_number FROM store_sales ss
  ),
  union_set AS (
    SELECT cs.cs_order_number AS order_key
    FROM catalog_sales cs
    UNION
    SELECT ss.ss_ticket_number FROM store_sales ss
  )
SELECT
  main.cc_name,
  main.s_store_name,
  main.d_year,
  main.total_sales,
  main.total_store_profit,
  main.avg_web_return,
  main.min_store_return_amt,
  main.distinct_items,
  main.distinct_orders,
  main.distinct_web_pages,
  main.distinct_web_sites,
  (SELECT COUNT(*) FROM except_set)        AS except_ticket_count,
  (SELECT COUNT(*) FROM intersect_set)    AS intersect_order_count,
  (SELECT COUNT(DISTINCT order_key) FROM union_set) AS union_distinct_order_keys
FROM main
ORDER BY main.total_sales DESC
LIMIT 100
