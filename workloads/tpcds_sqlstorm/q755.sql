WITH sales_data AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_order_number AS order_number,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_ticket_number,
    ss.ss_promo_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    'store'
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.ws_promo_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    'web'
  FROM web_sales ws
),
returns_data AS (
  SELECT
    cr.cr_returned_date_sk AS return_date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_order_number AS order_number,
    cr.cr_return_quantity AS quantity,
    cr.cr_return_amount AS return_amount,
    'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_item_sk,
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    'store'
  FROM store_returns sr
  UNION ALL
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_order_number,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    'web'
  FROM web_returns wr
),
joined AS (
  SELECT
    sd.sold_date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    sd.channel,
    SUM(sd.ext_sales_price) AS total_sales,
    SUM(sd.net_profit) AS total_profit,
    SUM(COALESCE(rd.return_amount, 0)) AS total_returns,
    SUM(COALESCE(rd.quantity, 0)) AS total_return_qty,
    COUNT(DISTINCT sd.order_number) AS orders,
    SUM(sd.quantity) AS total_quantity,
    COUNT(DISTINCT CASE WHEN sd.promo_sk IS NOT NULL THEN sd.promo_sk END) AS promo_count
  FROM sales_data sd
  LEFT JOIN returns_data rd
    ON sd.channel = rd.channel
    AND sd.item_sk = rd.item_sk
    AND sd.order_number = rd.order_number
  LEFT JOIN date_dim d
    ON sd.sold_date_sk = d.d_date_sk
  LEFT JOIN item i
    ON sd.item_sk = i.i_item_sk
  GROUP BY
    sd.sold_date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    sd.channel
),
final AS (
  SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    channel,
    total_sales,
    total_profit,
    total_returns,
    total_quantity,
    orders,
    promo_count,
    total_profit - total_returns AS net_profit_after_returns,
    total_sales - total_returns AS net_sales_after_returns,
    CASE WHEN total_sales > 0 THEN (total_profit - total_returns) / (total_sales - total_returns) ELSE NULL END AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_profit DESC) AS profit_rank_year_channel,
    SUM(total_profit - total_returns) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_channel,
    AVG(total_profit - total_returns) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_profit_3month_category,
    LAG(total_profit - total_returns) OVER (PARTITION BY i_category, channel ORDER BY d_year, d_month_seq) AS prev_month_profit_by_category_channel
  FROM joined
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_class,
  i_brand,
  channel,
  total_sales,
  total_profit,
  total_returns,
  total_quantity,
  orders,
  promo_count,
  net_profit_after_returns,
  net_sales_after_returns,
  profit_margin,
  profit_rank_year_channel,
  cumulative_profit_by_channel,
  moving_avg_profit_3month_category,
  prev_month_profit_by_category_channel
FROM final
ORDER BY d_year DESC, d_month_seq DESC, channel, total_sales DESC
LIMIT 100
