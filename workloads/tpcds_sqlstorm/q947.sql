WITH sales_union AS (
   SELECT cs_sold_date_sk AS date_sk,
          cs_item_sk AS item_sk,
          cs_quantity AS quantity,
          cs_net_paid AS net_paid,
          cs_net_profit AS net_profit,
          'catalog' AS channel,
          cs_order_number AS order_number,
          cs_promo_sk AS promo_sk
   FROM catalog_sales
   UNION ALL
   SELECT ss_sold_date_sk,
          ss_item_sk,
          ss_quantity,
          ss_net_paid,
          ss_net_profit,
          'store',
          ss_ticket_number,
          ss_promo_sk
   FROM store_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_quantity,
          ws_net_paid,
          ws_net_profit,
          'web',
          ws_order_number,
          ws_promo_sk
   FROM web_sales
),
returns_union AS (
   SELECT cr_returned_date_sk AS date_sk,
          cr_item_sk AS item_sk,
          cr_return_quantity AS quantity,
          cr_refunded_cash AS refunded_cash,
          cr_net_loss AS net_loss,
          'catalog' AS channel,
          cr_order_number AS order_number,
          cr_reason_sk AS reason_sk
   FROM catalog_returns
   UNION ALL
   SELECT sr_returned_date_sk,
          sr_item_sk,
          sr_return_quantity,
          sr_refunded_cash,
          sr_net_loss,
          'store',
          sr_ticket_number,
          sr_reason_sk
   FROM store_returns
   UNION ALL
   SELECT wr_returned_date_sk,
          wr_item_sk,
          wr_return_quantity,
          wr_refunded_cash,
          wr_net_loss,
          'web',
          wr_order_number,
          wr_reason_sk
   FROM web_returns
),
sales_agg AS (
   SELECT su.date_sk,
          su.channel,
          su.item_sk,
          SUM(su.quantity) AS total_quantity,
          SUM(su.net_paid) AS total_net_paid,
          SUM(su.net_profit) AS total_net_profit,
          COUNT(DISTINCT su.order_number) AS orders_cnt
   FROM sales_union su
   GROUP BY su.date_sk, su.channel, su.item_sk
),
returns_agg AS (
   SELECT ru.date_sk,
          ru.channel,
          ru.item_sk,
          SUM(ru.quantity) AS return_quantity,
          SUM(ru.refunded_cash) AS total_refunded_cash,
          SUM(ru.net_loss) AS total_net_loss,
          COUNT(DISTINCT ru.order_number) AS return_orders_cnt
   FROM returns_union ru
   GROUP BY ru.date_sk, ru.channel, ru.item_sk
),
joined AS (
   SELECT
       COALESCE(sa.date_sk, ra.date_sk) AS date_sk,
       COALESCE(sa.channel, ra.channel) AS channel,
       COALESCE(sa.item_sk, ra.item_sk) AS item_sk,
       COALESCE(sa.total_quantity, 0) AS total_quantity,
       COALESCE(sa.total_net_paid, 0) AS total_net_paid,
       COALESCE(sa.total_net_profit, 0) AS total_net_profit,
       COALESCE(ra.return_quantity, 0) AS return_quantity,
       COALESCE(ra.total_refunded_cash, 0) AS total_refunded_cash,
       COALESCE(ra.total_net_loss, 0) AS total_net_loss,
       COALESCE(sa.orders_cnt, 0) AS orders_cnt,
       COALESCE(ra.return_orders_cnt, 0) AS return_orders_cnt,
       (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS adjusted_net_profit
   FROM sales_agg sa
   FULL OUTER JOIN returns_agg ra
       ON sa.date_sk = ra.date_sk
      AND sa.channel = ra.channel
      AND sa.item_sk = ra.item_sk
),
item_sales AS (
   SELECT
       j.date_sk,
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       i.i_category AS category,
       i.i_class AS class,
       i.i_category_id,
       i.i_class_id,
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       j.channel,
       j.item_sk,
       j.total_quantity,
       j.total_net_paid,
       j.adjusted_net_profit,
       ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq, i.i_category ORDER BY j.adjusted_net_profit DESC) AS rank_in_category_month,
       SUM(j.adjusted_net_profit) OVER (PARTITION BY i.i_item_sk) AS cumulative_adj_profit_per_item,
       LAG(j.adjusted_net_profit) OVER (PARTITION BY i.i_item_sk ORDER BY d.d_year, d.d_month_seq) AS prior_month_adj_profit,
       CONCAT(i.i_category, ': ', COALESCE(i.i_product_name, 'Unknown')) AS category_product_desc,
       CASE 
           WHEN i.i_color IS NULL OR i.i_color = '' THEN 'NoColor'
           ELSE i.i_color
       END AS item_color_flag,
       (SELECT AVG(j2.adjusted_net_profit)
        FROM joined j2
        WHERE j2.item_sk = j.item_sk) AS avg_adj_profit_all_months
   FROM joined j
   LEFT JOIN date_dim d ON j.date_sk = d.d_date_sk
   LEFT JOIN item i ON j.item_sk = i.i_item_sk
   WHERE d.d_year >= 1999
     AND (i.i_size IS NOT NULL AND (i.i_size LIKE '%MEDIUM%' OR i.i_size LIKE '%LARGE%'))
     AND (i.i_brand_id IN (SELECT DISTINCT cd_demo_sk FROM customer_demographics WHERE cd_education_status = 'College'))
     AND (j.channel IS NOT NULL)
)
SELECT
    year,
    month_seq,
    category,
    class,
    item_id,
    product_name,
    channel,
    rank_in_category_month,
    total_quantity,
    total_net_paid,
    adjusted_net_profit,
    cumulative_adj_profit_per_item,
    prior_month_adj_profit,
    category_product_desc,
    item_color_flag,
    avg_adj_profit_all_months
FROM item_sales
WHERE rank_in_category_month <= 5
ORDER BY year, month_seq, category, rank_in_category_month
