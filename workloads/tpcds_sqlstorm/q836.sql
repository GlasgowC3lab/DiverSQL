WITH
sales_union AS (
  SELECT ss_sold_date_sk AS date_sk,
         ss_item_sk AS item_sk,
         ss_net_profit AS net_profit,
         ss_net_paid AS net_paid,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_item_sk,
         cs_net_profit,
         cs_net_paid,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_net_profit,
         ws_net_paid,
         'web' AS channel
  FROM web_sales
),
returns_union AS (
  SELECT sr_returned_date_sk AS date_sk,
         sr_item_sk AS item_sk,
         sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT cr_returned_date_sk,
         cr_item_sk,
         cr_net_loss,
         'catalog' AS channel
  FROM catalog_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         wr_net_loss,
         'web' AS channel
  FROM web_returns
),
agg_sales AS (
  SELECT su.date_sk,
         su.item_sk,
         SUM(su.net_profit) AS total_profit,
         SUM(su.net_paid) AS total_paid,
         COUNT(*) AS sales_cnt,
         COUNT(DISTINCT su.channel) AS channel_cnt
  FROM sales_union su
  GROUP BY su.date_sk, su.item_sk
),
agg_returns AS (
  SELECT ru.date_sk,
         ru.item_sk,
         SUM(ru.net_loss) AS total_loss,
         COUNT(*) AS returns_cnt
  FROM returns_union ru
  GROUP BY ru.date_sk, ru.item_sk
),
combined AS (
  SELECT COALESCE(s.date_sk, r.date_sk) AS date_sk,
         COALESCE(s.item_sk, r.item_sk) AS item_sk,
         COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0) AS net_result,
         COALESCE(s.total_paid, 0) AS total_paid,
         COALESCE(s.sales_cnt, 0) AS sales_cnt,
         COALESCE(r.returns_cnt, 0) AS returns_cnt,
         COALESCE(s.channel_cnt, 0) AS channel_cnt
  FROM agg_sales s
  FULL OUTER JOIN agg_returns r
    ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
),
windowed AS (
  SELECT c.date_sk,
         c.item_sk,
         c.net_result,
         c.total_paid,
         c.sales_cnt,
         c.returns_cnt,
         c.channel_cnt,
         SUM(c.net_result) OVER (
           PARTITION BY c.item_sk
           ORDER BY c.date_sk
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
         ) AS rolling_7day_sum,
         ROW_NUMBER() OVER (
           PARTITION BY c.date_sk
           ORDER BY c.net_result DESC
         ) AS rank_daily_profit,
         LAG(c.net_result) OVER (
           PARTITION BY c.item_sk
           ORDER BY c.date_sk
         ) AS prev_day_profit
  FROM combined c
  WHERE c.date_sk IS NOT NULL
),
item_info AS (
  SELECT i.i_item_sk,
         i.i_product_name,
         i.i_brand,
         i.i_category,
         i.i_color,
         COALESCE(NULLIF(i.i_color, ''), 'UNKNOWN') AS color_coalesced
  FROM item i
),
final AS (
  SELECT w.date_sk,
         w.item_sk,
         d.d_date AS sale_date,
         ii.i_product_name,
         ii.i_brand,
         ii.i_category,
         ii.color_coalesced,
         w.net_result,
         w.rolling_7day_sum,
         w.rank_daily_profit,
         w.prev_day_profit,
         CASE
           WHEN w.prev_day_profit IS NULL THEN NULL
           ELSE (w.net_result - w.prev_day_profit) / NULLIF(w.prev_day_profit, 0)
         END AS day_over_day_growth,
         (SELECT COUNT(DISTINCT cs.cs_bill_customer_sk)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = w.item_sk
              AND cs.cs_sold_date_sk = w.date_sk) AS catalog_customers,
         CASE WHEN EXISTS (
           SELECT 1 FROM promotion p
           WHERE p.p_item_sk = w.item_sk
             AND p.p_discount_active = 'Y'
             AND p.p_start_date_sk <= w.date_sk
             AND p.p_end_date_sk >= w.date_sk
         ) THEN 1 ELSE 0 END AS has_active_promo,
         CONCAT(ii.i_product_name, ' ',
                CASE
                  WHEN w.net_result > 10000 THEN 'HIGH'
                  WHEN w.net_result < -1000 THEN 'LOW'
                  ELSE 'MEDIUM'
                END) AS profit_tag,
         REGEXP_REPLACE(ii.i_product_name, '\\d', '#') AS masked_product_name,
         COALESCE(CAST(w.net_result AS VARCHAR), '0') AS net_result_str
  FROM windowed w
  LEFT JOIN date_dim d ON d.d_date_sk = w.date_sk
  LEFT JOIN item_info ii ON ii.i_item_sk = w.item_sk
  WHERE (w.channel_cnt > 1 OR w.sales_cnt >= 10)
    AND COALESCE(ii.i_brand, 'UNKNOWN') <> 'UNKNOWN'
    AND (d.d_year BETWEEN 2000 AND 2002 OR d.d_year IS NULL)
    AND NOT (ii.i_category = 'UNKNOWN' AND w.net_result = 0)
)
SELECT *
FROM final f
WHERE EXISTS (
  SELECT 1 FROM (
    SELECT item_sk, date_sk FROM final
    INTERSECT
    SELECT DISTINCT cs_item_sk AS item_sk, cs_sold_date_sk AS date_sk
    FROM catalog_sales
    WHERE cs_quantity > 5
  ) sub
  WHERE sub.item_sk = f.item_sk AND sub.date_sk = f.date_sk
)
ORDER BY f.date_sk DESC, f.rank_daily_profit
LIMIT 100
