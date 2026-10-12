WITH
  high_value_customers AS (
    SELECT c_customer_sk FROM (
      SELECT cs.cs_bill_customer_sk AS c_customer_sk
      FROM catalog_sales cs
      WHERE cs.cs_net_paid > 1000
      UNION
      SELECT ws.ws_bill_customer_sk AS c_customer_sk
      FROM web_sales ws
      WHERE ws.ws_net_paid > 500
    )
    EXCEPT
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_net_loss > 0
    INTERSECT
    SELECT c.c_customer_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
  ),
  sales_base AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_profit,
      i.i_category,
      d.d_year,
      cs.cs_bill_customer_sk,
      (SELECT AVG(cs2.cs_ext_discount_amt)
         FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_discount,
      -- additional joins to bring in all tables
      cc.cc_name,
      cp.cp_type,
      sm.sm_type,
      w.w_warehouse_name,
      we.web_name,
      r.r_reason_desc,
      s.s_store_name,
      inv.inv_quantity_on_hand,
      d_store.d_year AS store_closed_year,
      d_cc.d_year AS cc_closed_year
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i                    ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p               ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
    LEFT JOIN store_returns sr    ON sr.sr_item_sk        = cs.cs_item_sk
                                 AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
    LEFT JOIN reason r            ON sr.sr_reason_sk      = r.r_reason_sk
    LEFT JOIN web_sales ws        ON ws.ws_item_sk        = cs.cs_item_sk
                                 AND ws.ws_sold_date_sk   = cs.cs_sold_date_sk
    LEFT JOIN web_site we          ON ws.ws_web_site_sk    = we.web_site_sk
    LEFT JOIN store s              ON sr.sr_store_sk       = s.s_store_sk
    LEFT JOIN inventory inv        ON inv.inv_item_sk      = i.i_item_sk
                                 AND inv.inv_date_sk      = cs.cs_sold_date_sk
    LEFT JOIN date_dim d_store     ON s.s_closed_date_sk   = d_store.d_date_sk
    LEFT JOIN date_dim d_cc        ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE cs.cs_bill_customer_sk IN (SELECT c_customer_sk FROM high_value_customers)
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk AS i_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY inv.inv_item_sk
  )
SELECT
  sb.i_category,
  sb.d_year,
  SUM(sb.cs_net_profit)   AS total_profit,
  SUM(sb.cs_quantity)     AS total_quantity,
  COALESCE(ia.total_inventory, 0) AS inventory_on_2021,
  AVG(sb.avg_discount)    AS avg_discount
FROM sales_base sb
FULL OUTER JOIN inventory_agg ia
  ON sb.cs_item_sk = ia.i_item_sk
GROUP BY sb.i_category, sb.d_year, ia.total_inventory
ORDER BY total_profit DESC
LIMIT 100
