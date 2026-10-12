WITH unified_sales AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    i.i_category,
    p.p_promo_name AS promo_name,
    p.p_channel_tv,
    p.p_channel_email,
    cs.cs_quantity AS quantity,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
    AND d.d_quarter_name = 'Q4'
    AND i.i_category = 'Electronics'
  UNION ALL
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    i.i_category,
    p.p_promo_name AS promo_name,
    p.p_channel_tv,
    p.p_channel_email,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
    AND d.d_quarter_name = 'Q4'
    AND i.i_category = 'Electronics'
),
agg_sales AS (
  SELECT
    item_id,
    item_desc,
    promo_name,
    p_channel_tv,
    p_channel_email,
    SUM(quantity) AS total_quantity,
    SUM(net_profit) AS total_net_profit,
    AVG(discount_amt) AS avg_discount
  FROM unified_sales
  GROUP BY
    item_id,
    item_desc,
    promo_name,
    p_channel_tv,
    p_channel_email
  HAVING SUM(net_profit) > 0
)
SELECT
  item_id,
  item_desc,
  promo_name,
  COALESCE(p_channel_tv, 'N') AS channel_tv,
  COALESCE(p_channel_email, 'N') AS channel_email,
  total_quantity,
  total_net_profit,
  avg_discount,
  RANK() OVER (PARTITION BY COALESCE(p_channel_tv, 'N') ORDER BY total_net_profit DESC) AS profit_rank_tv,
  RANK() OVER (PARTITION BY COALESCE(p_channel_email, 'N') ORDER BY total_net_profit DESC) AS profit_rank_email
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 10
