WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      SUM(cs.cs_net_paid)          AS total_net_paid,
      SUM(cs.cs_quantity)          AS total_quantity,
      COUNT(*)                     AS sales_cnt,
      MAX(cs.cs_promo_sk)          AS any_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
  ),
  store_ret AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_amt,
      sr.sr_store_sk,
      r.r_reason_desc          AS store_reason,
      s.s_store_name,
      ca.ca_state,
      sr.sr_return_quantity
    FROM store_returns sr
    JOIN reason r          ON sr.sr_reason_sk   = r.r_reason_sk
    JOIN store s           ON sr.sr_store_sk    = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk   = ca.ca_address_sk
    WHERE sr.sr_return_amt > 0
  ),
  web_ret AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      wp.wp_url,
      ws.web_name,
      ca2.ca_state          AS returning_state,
      r2.r_reason_desc      AS web_reason
    FROM web_returns wr
    JOIN reason r2               ON wr.wr_reason_sk      = r2.r_reason_sk
    JOIN web_page wp             ON wr.wr_web_page_sk   = wp.wp_web_page_sk
    JOIN customer_address ca2    ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    JOIN date_dim d1             ON wr.wr_returned_date_sk = d1.d_date_sk
    JOIN web_site ws             ON ws.web_open_date_sk = d1.d_date_sk
    WHERE wr.wr_return_amt > 0
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
  ),
  combined AS (
    SELECT
      sa.cs_item_sk,
      sa.cs_sold_date_sk,
      sa.cs_sold_time_sk,
      sa.total_net_paid,
      sa.total_quantity,
      p.p_promo_name,
      p.p_discount_active,
      ra.total_return_amount,
      i.i_item_desc,
      d.d_year,
      t.t_hour,
      inv.total_on_hand,
      sr.sr_return_amt      AS store_return_amt,
      wr.wr_return_amt      AS web_return_amt,
      sr.store_reason,
      wr.web_reason
    FROM sales_agg sa
    JOIN item i               ON sa.cs_item_sk          = i.i_item_sk
    JOIN date_dim d            ON sa.cs_sold_date_sk    = d.d_date_sk
    JOIN time_dim t            ON sa.cs_sold_time_sk    = t.t_time_sk
    LEFT JOIN promotion p      ON sa.any_promo_sk       = p.p_promo_sk AND p.p_discount_active = 'Y'
    LEFT JOIN returns_agg ra  ON sa.cs_item_sk          = ra.cr_item_sk
                               AND sa.cs_sold_date_sk    = ra.cr_returned_date_sk
    LEFT JOIN inventory_agg inv ON sa.cs_item_sk        = inv.inv_item_sk
                               AND sa.cs_sold_date_sk    = inv.inv_date_sk
    FULL OUTER JOIN store_ret sr ON sr.sr_item_sk       = sa.cs_item_sk
    FULL OUTER JOIN web_ret  wr ON wr.wr_item_sk       = sa.cs_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND inv.total_on_hand > 0
  ),
  set_a AS (
    SELECT cs_item_sk, d_year, total_net_paid, total_quantity
    FROM combined
    WHERE total_net_paid > 1000
  ),
  set_b AS (
    SELECT cs_item_sk, d_year, total_net_paid, total_quantity
    FROM combined
    WHERE total_quantity > 50
  ),
  union_ab AS (
    SELECT * FROM set_a
    UNION
    SELECT * FROM set_b
  ),
  intersect_ab AS (
    SELECT * FROM set_a
    INTERSECT
    SELECT * FROM set_b
  ),
  except_ab AS (
    SELECT * FROM set_a
    EXCEPT
    SELECT * FROM set_b
  ),
  final_with_lateral AS (
    SELECT
      u.cs_item_sk,
      u.d_year,
      u.total_net_paid,
      u.total_quantity,
      lat.ten_percent,
      unn.metric
    FROM union_ab u
    CROSS JOIN LATERAL (
      SELECT u.total_net_paid * 0.1 AS ten_percent
    ) AS lat
    CROSS JOIN UNNEST(ARRAY[u.total_net_paid, u.total_quantity]) AS unn(metric)
    WHERE u.total_net_paid IS NOT NULL
  )
SELECT *
FROM final_with_lateral
LIMIT 100
