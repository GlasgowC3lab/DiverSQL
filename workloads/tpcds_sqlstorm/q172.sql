WITH
sales_base AS (
  SELECT cs_sold_date_sk AS sales_date_sk,
         cs_item_sk AS item_sk,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_item_sk,
         ss_quantity,
         ss_net_paid,
         ss_net_profit,
         'store'
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         'web'
  FROM web_sales
),
returns_base AS (
  SELECT cr_returned_date_sk AS return_date_sk,
         cr_item_sk AS item_sk,
         cr_return_quantity AS return_quantity,
         cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns
  UNION ALL
  SELECT sr_returned_date_sk,
         sr_item_sk,
         sr_return_quantity,
         sr_net_loss,
         'store'
  FROM store_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         wr_return_quantity,
         wr_net_loss,
         'web'
  FROM web_returns
),
sales_agg AS (
  SELECT
    s.item_sk,
    d.d_year,
    d.d_moy AS month_of_year,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    AVG(s.net_profit) AS avg_net_profit,
    COUNT(*) AS sales_transactions,
    CONCAT(i.i_brand, ' ', i.i_category, ' ', i.i_product_name) AS item_full_name
  FROM sales_base s
  JOIN date_dim d ON s.sales_date_sk = d.d_date_sk
  LEFT JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY s.item_sk, d.d_year, d.d_moy, s.channel, i.i_brand, i.i_category, i.i_product_name
),
returns_agg AS (
  SELECT
    r.item_sk,
    d.d_year,
    d.d_moy AS month_of_year,
    r.channel,
    SUM(r.return_quantity) AS total_return_quantity,
    SUM(r.net_loss) AS total_net_loss,
    COUNT(*) AS return_transactions
  FROM returns_base r
  JOIN date_dim d ON r.return_date_sk = d.d_date_sk
  GROUP BY r.item_sk, d.d_year, d.d_moy, r.channel
),
item_sales AS (
  SELECT
    sa.item_sk,
    sa.d_year,
    sa.month_of_year,
    sa.channel,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
    CASE
      WHEN sa.total_quantity = 0 THEN NULL
      ELSE (sa.total_net_profit - COALESCE(ra.total_net_loss,0)) / sa.total_quantity
    END AS profit_per_unit,
    ROW_NUMBER() OVER (PARTITION BY sa.channel ORDER BY (sa.total_net_profit - COALESCE(ra.total_net_loss,0)) DESC) AS rank_by_profit,
    sa.item_full_name
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.item_sk = ra.item_sk
    AND sa.d_year = ra.d_year
    AND sa.month_of_year = ra.month_of_year
    AND sa.channel = ra.channel
),
latest_period AS (
  SELECT MAX(d_year) AS max_year FROM item_sales
),
latest_month AS (
  SELECT MAX(month_of_year) AS max_month
  FROM item_sales
  WHERE d_year = (SELECT max_year FROM latest_period)
),
items_all_channels AS (
  SELECT item_sk
  FROM (
    SELECT DISTINCT item_sk
    FROM item_sales
    WHERE channel = 'catalog'
      AND d_year = (SELECT max_year FROM latest_period)
      AND month_of_year = (SELECT max_month FROM latest_month)
  ) cat
  INTERSECT
  SELECT item_sk
  FROM (
    SELECT DISTINCT item_sk
    FROM item_sales
    WHERE channel = 'store'
      AND d_year = (SELECT max_year FROM latest_period)
      AND month_of_year = (SELECT max_month FROM latest_month)
  ) sto
  INTERSECT
  SELECT item_sk
  FROM (
    SELECT DISTINCT item_sk
    FROM item_sales
    WHERE channel = 'web'
      AND d_year = (SELECT max_year FROM latest_period)
      AND month_of_year = (SELECT max_month FROM latest_month)
  ) web
),
profit_growth AS (
  SELECT
    isr.item_sk,
    isr.channel,
    isr.d_year,
    isr.month_of_year,
    isr.net_profit_after_returns,
    isr.profit_per_unit,
    isr.rank_by_profit,
    isr.item_full_name,
    COALESCE(
      (SELECT prev.net_profit_after_returns
       FROM item_sales prev
       WHERE prev.item_sk = isr.item_sk
         AND prev.channel = isr.channel
         AND (
              (isr.month_of_year = 1 AND prev.month_of_year = 12 AND prev.d_year = isr.d_year - 1)
              OR (isr.month_of_year <> 1 AND prev.month_of_year = isr.month_of_year - 1 AND prev.d_year = isr.d_year)
            )
      ), 0) AS prev_month_profit,
    (isr.net_profit_after_returns - COALESCE(
       (SELECT prev2.net_profit_after_returns
        FROM item_sales prev2
        WHERE prev2.item_sk = isr.item_sk
          AND prev2.channel = isr.channel
          AND (
               (isr.month_of_year = 1 AND prev2.month_of_year = 12 AND prev2.d_year = isr.d_year - 1)
               OR (isr.month_of_year <> 1 AND prev2.month_of_year = isr.month_of_year - 1 AND prev2.d_year = isr.d_year)
             )
       ), 0)
    ) AS profit_change,
    CASE
      WHEN COALESCE(
        (SELECT prev3.net_profit_after_returns
         FROM item_sales prev3
         WHERE prev3.item_sk = isr.item_sk
           AND prev3.channel = isr.channel
           AND (
                (isr.month_of_year = 1 AND prev3.month_of_year = 12 AND prev3.d_year = isr.d_year - 1)
                OR (isr.month_of_year <> 1 AND prev3.month_of_year = isr.month_of_year - 1 AND prev3.d_year = isr.d_year)
               )
        ), 0) = 0 THEN NULL
      ELSE (isr.net_profit_after_returns - COALESCE(
           (SELECT prev4.net_profit_after_returns
            FROM item_sales prev4
            WHERE prev4.item_sk = isr.item_sk
              AND prev4.channel = isr.channel
              AND (
                   (isr.month_of_year = 1 AND prev4.month_of_year = 12 AND prev4.d_year = isr.d_year - 1)
                   OR (isr.month_of_year <> 1 AND prev4.month_of_year = isr.month_of_year - 1 AND prev4.d_year = isr.d_year)
                 )
           ), 0))
           / COALESCE(
              (SELECT prev5.net_profit_after_returns
               FROM item_sales prev5
               WHERE prev5.item_sk = isr.item_sk
                 AND prev5.channel = isr.channel
                 AND (
                      (isr.month_of_year = 1 AND prev5.month_of_year = 12 AND prev5.d_year = isr.d_year - 1)
                      OR (isr.month_of_year <> 1 AND prev5.month_of_year = isr.month_of_year - 1 AND prev5.d_year = isr.d_year)
                    )
               ), 1)
    END AS profit_growth_pct
  FROM item_sales isr
),
final AS (
  SELECT
    pg.item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    pg.channel,
    pg.d_year,
    pg.month_of_year,
    pg.net_profit_after_returns,
    pg.prev_month_profit,
    pg.profit_change,
    pg.profit_growth_pct,
    pg.rank_by_profit,
    CASE
      WHEN pg.profit_growth_pct > 0.2 THEN 'High Growth'
      WHEN pg.profit_growth_pct BETWEEN 0 AND 0.2 THEN 'Moderate Growth'
      WHEN pg.profit_growth_pct < 0 THEN 'Decline'
      ELSE 'No Data'
    END AS growth_category,
    COALESCE(pg.profit_per_unit, 0) AS profit_per_unit,
    CASE
      WHEN i.i_color IS NULL THEN 'UNKNOWN_COLOR'
      ELSE i.i_color
    END AS item_color,
    CONCAT_WS(' ', i.i_brand, i.i_category, i.i_product_name) AS full_item_desc,
    pg.item_full_name
  FROM profit_growth pg
  JOIN item i ON pg.item_sk = i.i_item_sk
  JOIN latest_period lp ON pg.d_year = lp.max_year
  JOIN latest_month lm ON pg.month_of_year = lm.max_month
  WHERE pg.item_sk IN (SELECT item_sk FROM items_all_channels)
    AND pg.rank_by_profit <= 10
)
SELECT *
FROM final
ORDER BY channel, profit_growth_pct DESC, rank_by_profit
LIMIT 100
