WITH unified_sales AS (
   SELECT cs_bill_customer_sk AS customer_sk,
          cs_sold_date_sk AS date_sk,
          cs_net_profit AS net_profit,
          'catalog' AS sales_channel,
          cs_quantity AS quantity,
          cs_ext_sales_price AS ext_sales_price
   FROM catalog_sales
   UNION ALL
   SELECT ss_customer_sk,
          ss_sold_date_sk,
          ss_net_profit,
          'store' AS sales_channel,
          ss_quantity,
          ss_ext_sales_price
   FROM store_sales
   UNION ALL
   SELECT ws_bill_customer_sk,
          ws_sold_date_sk,
          ws_net_profit,
          'web' AS sales_channel,
          ws_quantity,
          ws_ext_sales_price
   FROM web_sales
),
customer_year_profit AS (
   SELECT
     us.customer_sk,
     d.d_year,
     SUM(us.net_profit) AS total_net_profit,
     SUM(us.ext_sales_price) AS total_ext_sales,
     SUM(us.quantity) AS total_quantity,
     ARRAY_AGG(DISTINCT us.sales_channel) AS sales_channels,
     COUNT(*) AS tx_count
   FROM unified_sales us
   JOIN date_dim d ON us.date_sk = d.d_date_sk
   GROUP BY us.customer_sk, d.d_year
),
customer_year_rank AS (
   SELECT
     cyp.customer_sk,
     cyp.d_year,
     cyp.total_net_profit,
     cyp.total_ext_sales,
     cyp.total_quantity,
     cyp.sales_channels,
     cyp.tx_count,
     ROW_NUMBER() OVER (PARTITION BY cyp.d_year ORDER BY cyp.total_net_profit DESC) AS profit_rank,
     AVG(cyp.total_net_profit) OVER (PARTITION BY cyp.d_year) AS avg_year_profit,
     MAX(cyp.total_net_profit) OVER (PARTITION BY cyp.d_year) AS max_year_profit,
     CASE WHEN cyp.total_net_profit > AVG(cyp.total_net_profit) OVER (PARTITION BY cyp.d_year) THEN 'ABOVE' ELSE 'BELOW' END AS profit_vs_avg,
     CONCAT(COALESCE(c.c_first_name, 'UNKNOWN'), ' ', COALESCE(c.c_last_name, '')) AS full_name,
     (cyp.total_net_profit * 100) % NULLIF(cyp.tx_count,0) AS profit_mod_tx,
     REPEAT('!', LEAST(ROW_NUMBER() OVER (PARTITION BY cyp.d_year ORDER BY cyp.total_net_profit DESC), 10)) AS rank_indicator
   FROM customer_year_profit cyp
   LEFT JOIN customer c ON cyp.customer_sk = c.c_customer_sk
),
returns_union AS (
   SELECT sr_customer_sk AS customer_sk,
          sr_returned_date_sk AS date_sk,
          sr_return_amt AS return_amount
   FROM store_returns
   UNION ALL
   SELECT cr_returning_customer_sk,
          cr_returned_date_sk,
          cr_return_amount
   FROM catalog_returns
   UNION ALL
   SELECT wr_refunded_customer_sk,
          wr_returned_date_sk,
          wr_return_amt
   FROM web_returns
),
customer_year_returns AS (
   SELECT
     ru.customer_sk,
     d.d_year,
     SUM(ru.return_amount) AS total_return_amount,
     COUNT(*) AS return_cnt
   FROM returns_union ru
   JOIN date_dim d ON ru.date_sk = d.d_date_sk
   GROUP BY ru.customer_sk, d.d_year
),
common_customers AS (
   SELECT ss_customer_sk AS customer_sk FROM store_sales
   INTERSECT
   SELECT ws_bill_customer_sk AS customer_sk FROM web_sales
),
final AS (
   SELECT
     cyr.profit_rank,
     cyr.d_year,
     cyr.full_name,
     cyr.customer_sk,
     cyr.total_net_profit,
     cyr.total_ext_sales,
     cyr.total_quantity,
     cyr.sales_channels,
     cyr.tx_count,
     cyr.avg_year_profit,
     cyr.max_year_profit,
     cyr.profit_vs_avg,
     cyr.profit_mod_tx,
     cyr.rank_indicator,
     COALESCE(cyr2.total_return_amount, 0) AS total_return_amount,
     COALESCE(cyr2.return_cnt, 0) AS return_cnt,
     CASE WHEN COALESCE(cyr2.return_cnt,0) > 0 THEN 'Y' ELSE 'N' END AS has_return,
     (SELECT MAX(cyp2.total_net_profit) FROM customer_year_profit cyp2 WHERE cyp2.d_year = cyr.d_year) AS max_yearly_profit,
     cardinality(filter(cyr.sales_channels, x -> x IN ('store','web','catalog'))) AS channel_count,
     CASE WHEN REGEXP_LIKE(cyr.full_name, '(?i)a') AND cyr.profit_rank <= 5 THEN 'FLAGGED' END AS special_flag
   FROM customer_year_rank cyr
   LEFT JOIN customer_year_returns cyr2 ON cyr.customer_sk = cyr2.customer_sk AND cyr.d_year = cyr2.d_year
   INNER JOIN common_customers cc ON cyr.customer_sk = cc.customer_sk
   WHERE cyr.profit_rank <= 10
     AND (cyr.total_net_profit IS NOT NULL OR cyr.tx_count IS NULL)
)
SELECT *
FROM final
ORDER BY d_year DESC, profit_rank
LIMIT 50
