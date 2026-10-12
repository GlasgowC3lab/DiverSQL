WITH cat_sales_agg AS (
   SELECT cs.cs_order_number,
          SUM(cs.cs_net_paid)               AS order_total,
          COUNT(*)                         AS line_cnt,
          MAX(cs.cs_sold_time_sk)          AS sold_time_sk,
          MAX(cs.cs_call_center_sk)        AS call_center_sk,
          MAX(cs.cs_ship_mode_sk)          AS ship_mode_sk,
          MAX(cs.cs_warehouse_sk)          AS warehouse_sk,
          MAX(cs.cs_promo_sk)              AS promo_sk,
          MAX(cs.cs_bill_customer_sk)      AS bill_cust_sk
   FROM tpcds.catalog_sales cs
   GROUP BY cs.cs_order_number
),
filtered_orders AS (
   SELECT cs_order_number
   FROM cat_sales_agg
   WHERE order_total > 2000
),
catalog_orders_excluded AS (
   SELECT cs_order_number
   FROM tpcds.catalog_sales
   EXCEPT
   SELECT cs_order_number FROM filtered_orders
),
web_return_keys AS (
   SELECT wr.wr_order_number AS order_number
   FROM tpcds.web_returns wr
),
catalog_return_keys AS (
   SELECT cr.cr_order_number AS order_number
   FROM tpcds.catalog_returns cr
),
common_return_orders AS (
   SELECT order_number FROM web_return_keys
   INTERSECT
   SELECT order_number FROM catalog_return_keys
),
final_data AS (
   SELECT
      csagg.cs_order_number,
      csagg.order_total,
      c.c_customer_id,
      p.p_promo_name,
      cc.cc_name                AS call_center_name,
      sm.sm_type                AS ship_mode_type,
      w.w_warehouse_name,
      td.t_hour,
      ss.ss_ticket_number,
      ws.ws_order_number        AS web_order_number,
      ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY csagg.order_total DESC) AS promo_rank
   FROM cat_sales_agg csagg
   JOIN tpcds.customer      c  ON csagg.bill_cust_sk = c.c_customer_sk
   JOIN tpcds.promotion     p  ON csagg.promo_sk      = p.p_promo_sk
   JOIN tpcds.call_center   cc ON csagg.call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode     sm ON csagg.ship_mode_sk   = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse     w  ON csagg.warehouse_sk   = w.w_warehouse_sk
   JOIN tpcds.time_dim      td ON csagg.sold_time_sk   = td.t_time_sk
   LEFT JOIN tpcds.store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
   LEFT JOIN tpcds.web_sales   ws ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE csagg.cs_order_number NOT IN (SELECT cs_order_number FROM catalog_orders_excluded)
     AND csagg.cs_order_number IN (SELECT order_number FROM common_return_orders)
     AND td.t_hour BETWEEN 9 AND 17
     AND w.w_gmt_offset BETWEEN -5 AND 0
     AND p.p_discount_active = 'Y'
     AND cc.cc_state = 'CA'
)
SELECT *
FROM final_data
WHERE promo_rank <= 5
ORDER BY p_promo_name, order_total DESC
LIMIT 100
