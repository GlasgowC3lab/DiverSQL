WITH sales_data AS (
  SELECT
    ws.ws_item_sk,
    ws.ws_promo_sk,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_sold_time_sk,
    ws.ws_sold_date_sk
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450806 AND 2451063
)
SELECT
  sub.i_item_id,
  sub.i_product_name,
  sub.p_promo_name,
  sub.p_channel_tv,
  sub.p_channel_email,
  sub.net_profit,
  sub.net_quantity,
  sub.num_orders,
  ROW_NUMBER() OVER (ORDER BY sub.net_profit DESC) AS profit_rank
FROM (
  SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_channel_email,
    SUM(sd.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
    SUM(sd.ws_quantity) - COALESCE(SUM(wr.wr_return_quantity), 0) AS net_quantity,
    COUNT(DISTINCT sd.ws_order_number) AS num_orders
  FROM sales_data sd
  JOIN item i ON sd.ws_item_sk = i.i_item_sk
  JOIN promotion p ON sd.ws_promo_sk = p.p_promo_sk
  JOIN time_dim td ON sd.ws_sold_time_sk = td.t_time_sk
  LEFT JOIN web_returns wr
    ON sd.ws_order_number = wr.wr_order_number
    AND sd.ws_item_sk = wr.wr_item_sk
  WHERE i.i_category = 'Electronics'
    AND (p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y')
    AND td.t_hour BETWEEN 12 AND 14
  GROUP BY i.i_item_id, i.i_product_name, p.p_promo_name, p.p_channel_tv, p.p_channel_email
  HAVING SUM(sd.ws_quantity) > 0
) sub
ORDER BY sub.net_profit DESC
LIMIT 20
