WITH cs_agg AS (
    SELECT cs_item_sk,
           SUM(cs_net_profit)          AS total_cs_profit,
           SUM(cs_ext_discount_amt)    AS total_cs_discount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs_ext_discount_amt > 100.00
      AND cs_ext_tax < 500.00
    GROUP BY cs_item_sk
)
SELECT i.i_category,
       i.i_brand,
       SUM(ss.ss_net_paid)                     AS total_store_sales,
       SUM(ws.ws_net_paid)                     AS total_web_sales,
       SUM(cs.cs_net_profit)                   AS total_catalog_profit,
       SUM(sr.sr_return_amt)                  AS total_store_return_amt,
       SUM(wr.wr_return_amt)                  AS total_web_return_amt,
       SUM(cs_agg.total_cs_profit)             AS total_agg_catalog_profit,
       SUM(cs_agg.total_cs_discount)           AS total_agg_catalog_discount,
       MAX(td.t_hour)                          AS max_sold_hour,
       MAX(ls.max_item_net_paid)               AS max_item_net_paid
FROM store_sales ss
FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN time_dim td
       ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
     ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
     ON ws.ws_web_site_sk = web.web_site_sk
JOIN cs_agg
     ON cs_agg.cs_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT MAX(ws2.ws_net_paid) AS max_item_net_paid
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = i.i_item_sk
) AS ls
WHERE c.c_birth_day = 7
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND i.i_category = 'Electronics'
  AND sm.sm_carrier = 'UPS'
  AND td.t_hour BETWEEN 8 AND 20
  AND EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_order_number = ws.ws_order_number
          AND wr3.wr_return_amt > 50
    )
GROUP BY i.i_category, i.i_brand
ORDER BY total_store_sales DESC
LIMIT 100
