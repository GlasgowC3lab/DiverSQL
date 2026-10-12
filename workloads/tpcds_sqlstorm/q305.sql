WITH sales AS (
  SELECT
    'Store' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category AS category,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS profit,
    0.0 AS loss,
    NULL AS call_center_name,
    p.p_promo_name AS promotion_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT
    'Catalog' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    cs.cs_net_paid,
    cs.cs_net_profit,
    0.0,
    cc.cc_name,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT
    'Web' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    ws.ws_net_paid,
    ws.ws_net_profit,
    0.0,
    NULL,
    p.p_promo_name
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
returns AS (
  SELECT
    'Store' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category AS category,
    0.0 AS net_paid,
    0.0 AS profit,
    sr.sr_net_loss AS loss,
    NULL AS call_center_name,
    NULL AS promotion_name
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    'Catalog' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    0.0,
    0.0,
    cr.cr_net_loss,
    cc.cc_name,
    NULL
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  UNION ALL
  SELECT
    'Web' AS channel,
    d.d_year,
    d.d_moy AS month,
    i.i_category,
    0.0,
    0.0,
    wr.wr_net_loss,
    NULL,
    NULL
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
unified AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
),
aggregated AS (
  SELECT
    channel,
    d_year,
    month,
    category,
    call_center_name,
    promotion_name,
    sum(net_paid) AS total_sales,
    sum(profit) AS total_profit,
    sum(loss) AS total_loss
  FROM unified
  GROUP BY
    channel,
    d_year,
    month,
    category,
    call_center_name,
    promotion_name
),
final AS (
  SELECT
    *,
    (total_profit - total_loss) AS net_profit,
    (total_sales - total_loss) AS net_revenue
  FROM aggregated
)
SELECT
  channel,
  d_year,
  month,
  category,
  call_center_name,
  promotion_name,
  total_sales,
  total_profit,
  total_loss,
  net_revenue,
  net_profit,
  avg(net_profit) OVER (PARTITION BY channel, category ORDER BY d_year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_moving_avg_3mo,
  rank() OVER (PARTITION BY d_year, month ORDER BY net_profit DESC) AS category_rank_month
FROM final
WHERE total_sales > 0
ORDER BY d_year, month, net_profit DESC
LIMIT 200
