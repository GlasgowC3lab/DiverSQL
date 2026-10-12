WITH
  sales_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      ss_sold_time_sk,
      SUM(ss_net_paid)    AS total_net_paid,
      COUNT(*)            AS sales_cnt
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451179
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_time_sk
  ),
  returns_store AS (
    SELECT
      sr_item_sk,
      sr_store_sk,
      sr_reason_sk,
      SUM(sr_net_loss) AS total_loss,
      COUNT(*)         AS return_cnt
    FROM store_returns
    GROUP BY sr_item_sk, sr_store_sk, sr_reason_sk
  ),
  catalog_agg AS (
    SELECT
      cr_item_sk,
      cr_warehouse_sk,
      cr_call_center_sk,
      SUM(cr_net_loss) AS catalog_loss,
      COUNT(*)         AS catalog_ret_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_warehouse_sk, cr_call_center_sk
  ),
  full_returns AS (
    SELECT
      rs.sr_item_sk,
      rs.sr_store_sk,
      rs.sr_reason_sk,
      rs.total_loss,
      rs.return_cnt,
      rc.cr_warehouse_sk,
      rc.cr_call_center_sk,
      rc.catalog_loss,
      rc.catalog_ret_cnt
    FROM returns_store rs
    FULL OUTER JOIN catalog_agg rc
      ON rs.sr_item_sk = rc.cr_item_sk
  ),
  web_sales_sub AS (
    SELECT
      ws_item_sk,
      ws_warehouse_sk,
      ws_sold_time_sk,
      ws_web_page_sk,
      ws_bill_addr_sk,
      SUM(ws_net_paid) AS ws_total_paid
    FROM web_sales
    TABLESAMPLE BERNOULLI (5)
    GROUP BY ws_item_sk, ws_warehouse_sk, ws_sold_time_sk, ws_web_page_sk, ws_bill_addr_sk
  ),
  common_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
  )
SELECT
  i.i_item_id,
  s.s_store_name,
  w_ws.w_warehouse_name               AS ws_warehouse,
  w_rc.w_warehouse_name               AS rc_warehouse,
  p.p_promo_name,
  ca.ca_city,
  t_sales.t_hour                       AS sales_hour,
  t_web.t_hour                         AS web_hour,
  SUM(sa.total_net_paid)              AS agg_total_net_paid,
  COUNT(DISTINCT ca.ca_address_sk)    AS distinct_addr_cnt,
  COUNT(DISTINCT i.i_category)        AS distinct_category_cnt,
  CASE WHEN SUM(sa.total_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_level,
  COALESCE(fr.total_loss, 0)          AS store_return_loss,
  COALESCE(fr.catalog_loss, 0)        AS catalog_return_loss,
  cc.cc_name                           AS call_center_name,
  r.r_reason_desc
FROM
  common_items ci
  JOIN item i               ON ci.item_sk = i.i_item_sk
  LEFT JOIN promotion p    ON p.p_item_sk = i.i_item_sk
  LEFT JOIN sales_agg sa   ON sa.ss_item_sk = i.i_item_sk
  LEFT JOIN store s        ON sa.ss_store_sk = s.s_store_sk
  LEFT JOIN time_dim t_sales ON t_sales.t_time_sk = sa.ss_sold_time_sk
  LEFT JOIN full_returns fr ON fr.sr_item_sk = i.i_item_sk
  LEFT JOIN reason r        ON fr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN warehouse w_rc  ON fr.cr_warehouse_sk = w_rc.w_warehouse_sk
  LEFT JOIN call_center cc  ON fr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_sales_sub ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN time_dim t_web  ON t_web.t_time_sk = ws.ws_sold_time_sk
  LEFT JOIN warehouse w_ws  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  LEFT JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN customer_address ca ON ca.ca_address_sk = ws.ws_bill_addr_sk
WHERE
  t_sales.t_hour BETWEEN 8 AND 20
GROUP BY
  i.i_item_id,
  s.s_store_name,
  w_ws.w_warehouse_name,
  w_rc.w_warehouse_name,
  p.p_promo_name,
  ca.ca_city,
  t_sales.t_hour,
  t_web.t_hour,
  fr.total_loss,
  fr.catalog_loss,
  cc.cc_name,
  r.r_reason_desc
ORDER BY
  agg_total_net_paid DESC
LIMIT 100
