WITH store_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ss.ss_quantity) AS store_qty
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE cd.cd_purchase_estimate > 1500
    AND cd.cd_marital_status = 'M'
    AND t.t_shift = 'Evening'
    AND d.d_year BETWEEN 2020 AND 2022
  GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  HAVING SUM(ss.ss_net_profit) > 10000
),
web_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ws.ws_quantity) AS web_qty
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE cd.cd_purchase_estimate > 1500
    AND cd.cd_marital_status = 'M'
    AND t.t_shift = 'Evening'
    AND d.d_year BETWEEN 2020 AND 2022
  GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  HAVING SUM(ws.ws_net_profit) > 8000
),
inv_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    SUM(i.inv_quantity_on_hand) AS total_inventory
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2020 AND 2022
  GROUP BY d.d_year, d.d_month_seq
)
SELECT
  COALESCE(sa.d_year, wa.d_year) AS year,
  COALESCE(sa.d_month_seq, wa.d_month_seq) AS month,
  COALESCE(sa.cd_gender, wa.cd_gender) AS gender,
  sa.store_profit,
  wa.web_profit,
  (sa.store_profit - wa.web_profit) AS profit_diff,
  ia.total_inventory,
  RANK() OVER (ORDER BY (sa.store_profit - wa.web_profit) DESC) AS profit_diff_rank
FROM store_agg sa
FULL OUTER JOIN web_agg wa
  ON sa.d_year = wa.d_year
 AND sa.d_month_seq = wa.d_month_seq
 AND sa.cd_gender = wa.cd_gender
LEFT JOIN inv_agg ia
  ON ia.d_year = COALESCE(sa.d_year, wa.d_year)
 AND ia.d_month_seq = COALESCE(sa.d_month_seq, wa.d_month_seq)
WHERE (sa.store_profit IS NOT NULL OR wa.web_profit IS NOT NULL)
ORDER BY profit_diff_rank
LIMIT 100
