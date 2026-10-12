WITH sales AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    cc.cc_state AS region,
    'catalog' AS channel,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS profit,
    cs.cs_ext_discount_amt AS discount,
    cs.cs_quantity AS quantity,
    0.0 AS loss,
    0 AS return_qty,
    0.0 AS return_amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    s.s_state AS region,
    'store' AS channel,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_net_profit AS profit,
    ss.ss_ext_discount_amt AS discount,
    ss.ss_quantity AS quantity,
    0.0 AS loss,
    0 AS return_qty,
    0.0 AS return_amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    ws_site.web_state AS region,
    'web' AS channel,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_net_profit AS profit,
    ws.ws_ext_discount_amt AS discount,
    ws.ws_quantity AS quantity,
    0.0 AS loss,
    0 AS return_qty,
    0.0 AS return_amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
returns AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    cc.cc_state AS region,
    'catalog' AS channel,
    0.0 AS sales_amount,
    0.0 AS profit,
    0.0 AS discount,
    0 AS quantity,
    cr.cr_net_loss AS loss,
    cr.cr_return_quantity AS return_qty,
    cr.cr_return_amount AS return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    s.s_state AS region,
    'store' AS channel,
    0.0 AS sales_amount,
    0.0 AS profit,
    0.0 AS discount,
    0 AS quantity,
    sr.sr_net_loss AS loss,
    sr.sr_return_quantity AS return_qty,
    sr.sr_return_amt AS return_amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    cd.cd_gender AS gender,
    NULL AS region,
    'web' AS channel,
    0.0 AS sales_amount,
    0.0 AS profit,
    0.0 AS discount,
    0 AS quantity,
    wr.wr_net_loss AS loss,
    wr.wr_return_quantity AS return_qty,
    wr.wr_return_amt AS return_amount
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
),
combined AS (
  SELECT
    year,
    month_seq,
    category,
    gender,
    region,
    channel,
    sum(sales_amount) AS total_sales,
    sum(profit) AS total_profit,
    sum(discount) AS total_discount,
    sum(quantity) AS total_quantity,
    sum(loss) AS total_loss,
    sum(return_qty) AS total_return_qty,
    sum(return_amount) AS total_return_amount,
    sum(profit) - sum(loss) AS net_profit
  FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
  ) all_data
  GROUP BY year, month_seq, category, gender, region, channel
)
SELECT
  year,
  month_seq,
  category,
  gender,
  region,
  channel,
  total_sales,
  total_profit,
  total_discount,
  total_quantity,
  total_loss,
  total_return_qty,
  total_return_amount,
  net_profit,
  rank() OVER (PARTITION BY year, month_seq ORDER BY net_profit DESC) AS profit_rank,
  avg(net_profit) OVER (PARTITION BY category, gender ORDER BY year, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_avg
FROM combined
WHERE year = 2001
ORDER BY year, month_seq, category, gender, channel
