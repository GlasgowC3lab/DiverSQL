/*
  Goal: Identify the top‑5 best‑selling items per store, combining sales from catalog, store, and web channels, while including return losses and a profitability flag. The query joins all 15 selected TPC‑DS tables, re‑uses dimension tables under multiple aliases, uses a RIGHT OUTER JOIN (store_sales → store), a CASE expression, a scalar sub‑query comparison, and a ranking window to keep only the top‑5 items per store.
*/
WITH
  -- Aggregate sales and returns across all channels
  aggregated AS (
    SELECT
      s.s_store_id,
      i.i_item_id,
      d.d_year,
      SUM(cs.cs_net_paid)                AS catalog_sales_total,
      SUM(ss.ss_net_paid)                AS store_sales_total,
      SUM(ws.ws_net_paid)                AS web_sales_total,
      SUM(cr.cr_net_loss)                AS catalog_returns_loss,
      SUM(sr.sr_net_loss)                AS store_returns_loss,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                        AND cr.cr_item_sk = cs.cs_item_sk
                                        AND cr.cr_returned_date_sk = d.d_date_sk
    /* RIGHT OUTER JOIN store_sales to store – keeps stores with no sales */
    JOIN (
      store_sales ss
      RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    ) ON ss.ss_sold_date_sk = d.d_date_sk
         AND ss.ss_item_sk = i.i_item_sk
         AND ss.ss_customer_sk = c.c_customer_sk
         AND ss.ss_cdemo_sk = cd.cd_demo_sk
         AND ss.ss_addr_sk = ca.ca_address_sk
         AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_item_sk = i.i_item_sk
                                         AND sr.sr_customer_sk = c.c_customer_sk
                                         AND sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws                  ON ws.ws_sold_date_sk = d.d_date_sk
                                         AND ws.ws_item_sk = i.i_item_sk
                                         AND ws.ws_bill_customer_sk = c.c_customer_sk
                                         AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                                         AND ws.ws_warehouse_sk = w.w_warehouse_sk
                                         AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site web                  ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cs.cs_net_paid > (
            SELECT MAX(cs2.cs_net_paid)
            FROM catalog_sales cs2
          )
    GROUP BY s.s_store_id, i.i_item_id, d.d_year
  ),
  -- Rank items per store by total catalog sales
  ranked AS (
    SELECT
      a.*, 
      ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.catalog_sales_total DESC) AS rn
    FROM aggregated a
  )
SELECT
  s_store_id,
  i_item_id,
  d_year,
  catalog_sales_total,
  store_sales_total,
  web_sales_total,
  catalog_returns_loss,
  store_returns_loss,
  profit_category
FROM ranked
WHERE rn <= 5
ORDER BY s_store_id, catalog_sales_total DESC
