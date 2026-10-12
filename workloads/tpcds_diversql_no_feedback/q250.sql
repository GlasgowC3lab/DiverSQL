WITH base AS (
  SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    cs.cs_net_profit AS catalog_net_profit,
    ws.ws_net_profit AS web_net_profit,
    wr.wr_net_loss AS return_net_loss
  FROM web_sales ws
  RIGHT OUTER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_sales cs
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  WHERE
    cs.cs_ext_ship_cost > 300
    AND cs.cs_coupon_amt < 2000
    AND ws.ws_list_price > 50
    AND p.p_response_target = 1
    AND p.p_channel_radio = 'N'
    AND wr.wr_return_amt > 0
    AND wp.wp_type = 'article'
),
agg AS (
  SELECT
    wp_web_page_id,
    wp_type,
    SUM(COALESCE(catalog_net_profit, 0)) AS total_catalog_profit,
    SUM(COALESCE(web_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(return_net_loss, 0)) AS total_return_loss,
    (SUM(COALESCE(catalog_net_profit, 0)) + SUM(COALESCE(web_net_profit, 0)) - SUM(COALESCE(return_net_loss, 0))) AS total_profit
  FROM base
  GROUP BY wp_web_page_id, wp_type
)
SELECT
  wp_web_page_id,
  wp_type,
  total_catalog_profit,
  total_web_profit,
  total_return_loss,
  total_profit,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank, wp_web_page_id
