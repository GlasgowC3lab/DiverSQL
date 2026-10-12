WITH store_agg AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    date_trunc('month', d.d_date) AS month,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_quantity) AS quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    AND i.i_category_id IN (1, 2, 3)
    AND cd.cd_gender IN ('M', 'F')
  GROUP BY i.i_category, cd.cd_gender, date_trunc('month', d.d_date)
),
catalog_agg AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    date_trunc('month', d.d_date) AS month,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_quantity) AS quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    AND cp.cp_type = 'monthly'
    AND i.i_category_id IN (1, 2, 3)
    AND cd.cd_gender IN ('M', 'F')
  GROUP BY i.i_category, cd.cd_gender, date_trunc('month', d.d_date)
),
web_agg AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    date_trunc('month', d.d_date) AS month,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_quantity) AS quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
    AND i.i_category_id IN (1, 2, 3)
    AND cd.cd_gender IN ('M', 'F')
  GROUP BY i.i_category, cd.cd_gender, date_trunc('month', d.d_date)
),
combined AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
),
monthly_summary AS (
  SELECT
    i_category,
    cd_gender,
    month,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity
  FROM combined
  GROUP BY i_category, cd_gender, month
),
 growth AS (
  SELECT
    i_category,
    cd_gender,
    month,
    total_net_profit,
    total_quantity,
    LAG(total_net_profit) OVER (PARTITION BY i_category, cd_gender ORDER BY month) AS prev_month_profit,
    CASE
      WHEN LAG(total_net_profit) OVER (PARTITION BY i_category, cd_gender ORDER BY month) = 0 THEN NULL
      ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY i_category, cd_gender ORDER BY month))
           / LAG(total_net_profit) OVER (PARTITION BY i_category, cd_gender ORDER BY month)
    END AS mom_profit_growth
  FROM monthly_summary
)
SELECT
  i_category,
  cd_gender,
  date_format(month, '%Y-%m') AS month,
  round(total_net_profit, 2) AS total_net_profit,
  total_quantity,
  round(mom_profit_growth * 100, 2) AS mom_profit_growth_pct
FROM growth
WHERE month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12' MONTH)
ORDER BY i_category, cd_gender, month
