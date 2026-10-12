WITH
  store_data AS (
    SELECT
      d.d_year,
      'store' AS channel,
      ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_net_profit > 0
      AND ss.ss_item_sk IN (
        SELECT cs_item_sk
        FROM catalog_sales
        WHERE cs_quantity > 5
      )
  ),
  web_data AS (
    SELECT
      d.d_year,
      'web' AS channel,
      ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_state = 'CA'
      AND ws.ws_net_profit > 0
      AND ws.ws_item_sk IN (
        SELECT cs_item_sk
        FROM catalog_sales
        WHERE cs_quantity > 5
      )
  ),
  union_data AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
  ),
  aggregated AS (
    SELECT
      d_year,
      channel,
      SUM(net_profit) AS total_profit
    FROM union_data
    GROUP BY ROLLUP (d_year, channel)
  ),
  ranked AS (
    SELECT
      d_year,
      channel,
      total_profit,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
    FROM aggregated
    WHERE d_year IS NOT NULL AND channel IS NOT NULL
  ),
  final AS (
    SELECT d_year, channel, total_profit
    FROM ranked
    WHERE rn <= 5
    UNION ALL
    SELECT d_year, channel, total_profit
    FROM aggregated
    WHERE d_year IS NULL OR channel IS NULL
  )
SELECT d_year,
       channel,
       total_profit
FROM final
ORDER BY d_year NULLS LAST,
         total_profit DESC,
         channel
LIMIT 100
