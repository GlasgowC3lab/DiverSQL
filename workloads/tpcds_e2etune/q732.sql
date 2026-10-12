WITH sales_by_channel AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    'catalog' AS channel,
    cd.cd_gender AS gender,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    SUM(cs.cs_quantity) AS quantity
  FROM catalog_sales cs
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451179
  GROUP BY cs.cs_item_sk, cd.cd_gender
  UNION ALL
  SELECT
    ss.ss_item_sk AS item_sk,
    'store' AS channel,
    cd.cd_gender AS gender,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_quantity) AS quantity
  FROM store_sales ss
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451179
  GROUP BY ss.ss_item_sk, cd.cd_gender
  UNION ALL
  SELECT
    ws.ws_item_sk AS item_sk,
    'web' AS channel,
    cd.cd_gender AS gender,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_quantity) AS quantity
  FROM web_sales ws
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
  GROUP BY ws.ws_item_sk, cd.cd_gender
),
web_returns_agg AS (
  SELECT
    wr.wr_item_sk AS item_sk,
    cd.cd_gender AS gender,
    r.r_reason_desc AS return_reason,
    wp.wp_type AS page_type,
    SUM(wr.wr_return_amt_inc_tax) AS return_amount,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  GROUP BY wr.wr_item_sk, cd.cd_gender, r.r_reason_desc, wp.wp_type
)
SELECT
  s.item_sk,
  s.channel,
  s.gender,
  s.net_profit,
  s.sales_amount,
  s.quantity,
  COALESCE(r.return_amount, 0) AS total_return_amount,
  COALESCE(r.return_cnt, 0) AS total_return_cnt,
  CASE WHEN s.sales_amount > 0 THEN COALESCE(r.return_amount, 0) / s.sales_amount ELSE NULL END AS return_ratio,
  ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY s.net_profit DESC) AS profit_rank
FROM sales_by_channel s
LEFT JOIN web_returns_agg r
  ON s.item_sk = r.item_sk AND s.gender = r.gender
WHERE s.net_profit > 500
ORDER BY s.channel, profit_rank
LIMIT 100
