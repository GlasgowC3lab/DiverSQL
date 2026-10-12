WITH
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      d.d_date,
      d.d_year,
      i.i_item_sk,
      i.i_category,
      i.i_current_price,
      cd.cd_gender,
      hd.hd_buy_potential,
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      p.p_promo_sk,
      p.p_discount_active,
      cs.cs_order_number,
      cs.cs_net_profit      AS cs_net_profit,
      cr.cr_net_loss,
      r.r_reason_desc,
      inv.inv_quantity_on_hand,
      ws.ws_order_number,
      ws.ws_net_profit      AS ws_net_profit,
      wp.wp_url,
      we.web_name,
      wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs    ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws        ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we         ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr     ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '1000-1999'
      AND ss.ss_store_sk IN (
        SELECT s2.s_store_sk FROM store s2 WHERE s2.s_market_id = 15
      )
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY cs_net_profit DESC NULLS LAST) AS rn_cs,
      RANK()       OVER (ORDER BY (cs_net_profit + ws_net_profit) DESC)           AS overall_rank
    FROM base
  ),
  small_stores AS (
    SELECT s_store_sk, s_store_name
    FROM store
    WHERE s_state = 'CA'
    ORDER BY s_number_employees DESC
    LIMIT 5
  ),
  promo_stats AS (
    SELECT
      p.p_promo_sk,
      AVG(p.p_cost)                     AS avg_promo_cost,
      COUNT(DISTINCT cs.cs_order_number) AS orders_covered
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
    HAVING COUNT(cs.cs_order_number) > 10
  )
SELECT
  rs.d_date,
  rs.s_store_name,
  rs.i_category,
  rs.i_current_price,
  rs.cs_net_profit,
  rs.ws_net_profit,
  rs.overall_rank,
  ps.avg_promo_cost,
  ps.orders_covered,
  rs.r_reason_desc
FROM ranked rs
CROSS JOIN promo_stats ps
JOIN small_stores ss ON rs.s_store_sk = ss.s_store_sk
ORDER BY rs.overall_rank
LIMIT 100
