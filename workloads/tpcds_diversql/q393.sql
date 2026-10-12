WITH
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      td.t_hour,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      p.p_channel_tv,
      ss.ss_net_profit   AS ss_net_profit,
      cs.cs_net_profit   AS cs_net_profit,
      ws.ws_net_profit   AS ws_net_profit,
      wsite.web_manager  AS web_manager
    FROM store_sales ss
    JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs          ON cs.cs_sold_time_sk = td.t_time_sk
                                   AND cs.cs_item_sk = i.i_item_sk
                                   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws              ON ws.ws_sold_time_sk = td.t_time_sk
                                   AND ws.ws_item_sk = i.i_item_sk
                                   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site wsite            ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE td.t_hour IN (10, 12, 14)
      AND i.i_brand = 'BrandA'
      AND wsite.web_manager = 'Jimmy Pope'
      AND NOT EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
          )
  ),
  agg_item AS (
    SELECT
      i_item_sk,
      SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit) AS item_profit,
      MAX(t_hour) AS max_hour
    FROM base
    GROUP BY i_item_sk
  ),
  intersect_items AS (
    SELECT i_item_sk FROM agg_item WHERE item_profit > 1000
    INTERSECT
    SELECT i_item_sk FROM agg_item WHERE max_hour = 12
  ),
  cube_agg AS (
    SELECT
      i_category,
      t_hour,
      i_item_sk,
      SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit) AS total_net_profit
    FROM base
    GROUP BY CUBE(i_category, t_hour, i_item_sk)
    HAVING SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit) > 0
  )
SELECT
  ca.i_category,
  ca.t_hour,
  ca.i_item_sk,
  ca.total_net_profit,
  ROW_NUMBER() OVER (PARTITION BY ca.i_category ORDER BY ca.total_net_profit DESC) AS rank_within_category
FROM cube_agg ca
JOIN intersect_items ii ON ca.i_item_sk = ii.i_item_sk
ORDER BY ca.total_net_profit DESC
LIMIT 100
