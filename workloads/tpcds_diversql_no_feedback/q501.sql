WITH filtered AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_fee,
       cr.cr_order_number,
       cc.cc_name,
       cc.cc_state,
       ca.ca_state,
       cd.cd_gender,
       d.d_year,
       d.d_quarter_seq,
       s.s_store_name,
       ws.ws_net_profit,
       ws.ws_ext_ship_cost,
       ws.ws_coupon_amt
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN store s
     ON s.s_closed_date_sk = d.d_date_sk
   JOIN customer_address ca
     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws
     ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_quarter_seq = 20
     AND d.d_year = 2001
     AND cc.cc_state = 'CA'
     AND ca.ca_state = 'CA'
     AND cd.cd_gender = 'M'
     AND cr.cr_fee > 20
     AND ws.ws_ext_ship_cost > 500
     AND NOT EXISTS (
         SELECT 1 FROM web_sales ws2
         WHERE ws2.ws_order_number = cr.cr_order_number
           AND ws2.ws_sold_date_sk = cr.cr_returned_date_sk
     )
),
agg AS (
   SELECT
       f.s_store_name,
       f.d_year,
       f.cc_name,
       COUNT(DISTINCT f.cr_order_number) AS distinct_return_orders,
       SUM(f.cr_return_amount) AS total_return_amount,
       AVG(f.ws_net_profit) AS avg_net_profit,
       MIN(f.ws_coupon_amt) AS min_coupon,
       MAX(f.ws_ext_ship_cost) AS max_ship_cost
   FROM filtered f
   GROUP BY f.s_store_name, f.d_year, f.cc_name
   HAVING SUM(f.cr_return_amount) > 10000
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_return_amount DESC) AS store_rank
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
