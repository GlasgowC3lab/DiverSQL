WITH customer_sales AS (
   SELECT
     c.c_customer_sk,
     c.c_customer_id,
     cd.cd_gender,
     cp.cp_catalog_page_id,
     sm.sm_type AS ship_type,
     i.i_item_sk,
     i.i_item_id,
     i.i_brand,
     sr.sr_ticket_number,
     sr.sr_return_amt,
     ws.ws_order_number,
     ws.ws_net_profit,
     cs.cs_net_profit,
     cs.cs_sold_date_sk
   FROM catalog_sales cs
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN web_page wp
     ON wp.wp_customer_sk = c.c_customer_sk
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND cp.cp_catalog_number > 5
     AND i.i_current_price > 100
     AND sm.sm_type = 'AIR'
     AND s.s_state = 'CA'
)
SELECT
  cs.c_customer_id,
  cs.i_item_id,
  cs.i_brand,
  cs.cp_catalog_page_id,
  cs.ship_type,
  cs.sr_return_amt,
  cs.ws_net_profit,
  cs.cs_net_profit,
  SUM(cs.cs_net_profit + cs.ws_net_profit - cs.sr_return_amt) OVER (
        PARTITION BY cs.c_customer_id
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      ) AS rolling_profit,
  RANK() OVER (
        PARTITION BY cs.c_customer_id
        ORDER BY cs.cs_sold_date_sk DESC
      ) AS recent_rank,
  CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
FROM customer_sales cs
CROSS JOIN (VALUES ('A'), ('B'), ('C')) AS dim(letter)
WHERE cs.sr_ticket_number NOT IN (
        SELECT ws_order_number FROM web_sales
      )
ORDER BY cs.c_customer_id, cs.cs_sold_date_sk DESC
LIMIT 100
