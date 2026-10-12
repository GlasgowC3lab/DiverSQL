WITH item_words AS (
   SELECT i_item_sk,
          split(i_item_desc, ' ') AS word_arr
   FROM item
)
SELECT
   d_sold.d_year,
   sm.sm_ship_mode_id,
   sm.sm_carrier,
   webs.web_site_id,
   SUM(ws.ws_net_paid) AS total_net_paid,
   COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
   MAX(wr.wr_net_loss) AS max_return_loss
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_site webs
  ON ws.ws_web_site_sk = webs.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN item_words iw
  ON iw.i_item_sk = i.i_item_sk
CROSS JOIN UNNEST(iw.word_arr) AS t(word)
WHERE d_sold.d_year = 2001
  AND sm.sm_carrier = 'DHL'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
          AND cs.cs_sold_date_sk = d_sold.d_date_sk
          AND cs.cs_quantity > 5
    )
GROUP BY d_sold.d_year,
         sm.sm_ship_mode_id,
         sm.sm_carrier,
         webs.web_site_id
HAVING SUM(ws.ws_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
