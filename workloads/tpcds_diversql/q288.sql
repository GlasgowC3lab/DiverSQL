WITH
  catalog_agg AS (
    SELECT
      cr_item_sk,
      SUM(cr_net_loss)          AS catalog_net_loss,
      COUNT(*)                  AS catalog_return_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk
  ),
  call_center_agg AS (
    SELECT
      cr_item_sk,
      MIN(cr_call_center_sk)    AS call_center_sk
    FROM catalog_returns
    GROUP BY cr_item_sk
  ),
  common_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
  ),
  sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
    WHERE i_item_sk IN (SELECT item_sk FROM common_items)
  ),
  joined_data AS (
    SELECT
      si.i_item_id,
      si.i_product_name,
      w.w_city,
      r.r_reason_desc,
      r_web.r_reason_desc               AS web_return_reason,
      ss.ss_net_profit,
      ws.ws_net_profit,
      sr.sr_net_loss,
      wr.wr_net_loss,
      ca.catalog_net_loss,
      ts_store.t_hour                    AS store_hour,
      ts_web.t_hour                      AS web_hour,
      ca_addr.ca_city                    AS store_customer_city,
      cd_demo.cd_gender,
      wp.wp_url,
      wsite.web_name,
      sm.sm_type,
      cc.cc_name
    FROM sampled_items si
    JOIN catalog_agg ca               ON ca.cr_item_sk = si.i_item_sk
    JOIN call_center_agg cca          ON cca.cr_item_sk = si.i_item_sk
    JOIN call_center cc               ON cc.cc_call_center_sk = cca.call_center_sk
    JOIN store_sales ss               ON ss.ss_item_sk = si.i_item_sk
    JOIN store_returns sr             ON sr.sr_item_sk = si.i_item_sk
                                         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws                 ON ws.ws_item_sk = si.i_item_sk
    JOIN web_returns wr               ON wr.wr_item_sk = si.i_item_sk
                                         AND wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w                  ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN reason r                     ON r.r_reason_sk = sr.sr_reason_sk
    JOIN reason r_web                 ON r_web.r_reason_sk = wr.wr_reason_sk
    JOIN ship_mode sm                 ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN time_dim ts_store            ON ts_store.t_time_sk = ss.ss_sold_time_sk
    JOIN time_dim ts_web              ON ts_web.t_time_sk = ws.ws_sold_time_sk
    JOIN customer_address ca_addr     ON ca_addr.ca_address_sk = ss.ss_addr_sk
    JOIN customer_demographics cd_demo ON cd_demo.cd_demo_sk = ss.ss_cdemo_sk
    JOIN web_page wp                  ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site wsite                ON wsite.web_site_sk = ws.ws_web_site_sk
  ),
  agg_summary AS (
    SELECT
      i_item_id,
      i_product_name,
      w_city,
      r_reason_desc,
      SUM(ss_net_profit)                                 AS store_sales_profit,
      SUM(ws_net_profit)                                 AS web_sales_profit,
      SUM(sr_net_loss)                                   AS store_returns_loss,
      SUM(wr_net_loss)                                   AS web_returns_loss,
      SUM(catalog_net_loss)                              AS catalog_returns_loss,
      CASE
        WHEN SUM(ss_net_profit + ws_net_profit - sr_net_loss - wr_net_loss - catalog_net_loss) > 10000 THEN 'HIGH'
        ELSE 'LOW'
      END                                                AS profit_category,
      SUM(ss_net_profit + ws_net_profit - sr_net_loss - wr_net_loss - catalog_net_loss) AS total_profit
    FROM joined_data
    GROUP BY i_item_id, i_product_name, w_city, r_reason_desc
  )
SELECT
  i_item_id,
  i_product_name,
  w_city,
  r_reason_desc,
  store_sales_profit,
  web_sales_profit,
  store_returns_loss,
  web_returns_loss,
  catalog_returns_loss,
  profit_category,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_profit DESC) AS profit_rank
FROM agg_summary
ORDER BY profit_rank
LIMIT 100
