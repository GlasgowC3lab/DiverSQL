WITH unified_sales AS (
   SELECT
     cs.cs_sold_date_sk AS sold_date_sk,
     cs.cs_item_sk AS item_sk,
     cs.cs_bill_customer_sk AS customer_sk,
     cs.cs_sold_time_sk AS time_sk,
     cs.cs_net_paid AS net_paid,
     cs.cs_net_profit AS net_profit,
     cs.cs_quantity AS quantity,
     cs.cs_promo_sk AS promo_sk,
     'Catalog' AS channel
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk IS NOT NULL
   UNION ALL
   SELECT
     ss.ss_sold_date_sk,
     ss.ss_item_sk,
     ss.ss_customer_sk,
     ss.ss_sold_time_sk,
     ss.ss_net_paid,
     ss.ss_net_profit,
     ss.ss_quantity,
     ss.ss_promo_sk,
     'Store' AS channel
   FROM store_sales ss
   WHERE ss.ss_sold_date_sk IS NOT NULL
   UNION ALL
   SELECT
     ws.ws_sold_date_sk,
     ws.ws_item_sk,
     ws.ws_bill_customer_sk,
     ws.ws_sold_time_sk,
     ws.ws_net_paid,
     ws.ws_net_profit,
     ws.ws_quantity,
     ws.ws_promo_sk,
     'Web' AS channel
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk IS NOT NULL
),
sales_enriched AS (
   SELECT
     us.sold_date_sk,
     d.d_date,
     format_datetime(d.d_date, 'yyyy-MM') AS year_month,
     us.item_sk,
     i.i_category AS category,
     i.i_class AS class,
     i.i_brand AS brand,
     i.i_color AS color,
     us.customer_sk,
     c.c_preferred_cust_flag,
     us.channel,
     us.quantity,
     us.net_paid,
     us.net_profit,
     COALESCE(p.p_discount_active, 'N') AS promo_active
   FROM unified_sales us
   LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON us.item_sk = i.i_item_sk
   LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
   LEFT JOIN customer c ON us.customer_sk = c.c_customer_sk
),
filtered_sales AS (
   SELECT *
   FROM sales_enriched
   WHERE d_date IS NOT NULL
     AND category IS NOT NULL
),
agg_sales AS (
   SELECT
     year_month,
     channel,
     category,
     SUM(net_paid) AS total_net_paid,
     SUM(net_profit) AS total_net_profit,
     SUM(quantity) AS total_quantity,
     COUNT(DISTINCT customer_sk) AS distinct_customers,
     SUM(CASE WHEN promo_active = 'Y' THEN net_paid ELSE 0 END) AS promo_net_paid
   FROM filtered_sales
   GROUP BY year_month, channel, category
),
ranked_sales AS (
   SELECT
     *,
     ROW_NUMBER() OVER (PARTITION BY year_month, channel ORDER BY total_net_profit DESC) AS profit_rank
   FROM agg_sales
)
SELECT
   year_month,
   channel,
   category,
   total_net_paid,
   total_net_profit,
   total_quantity,
   distinct_customers,
   promo_net_paid,
   profit_rank
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY year_month DESC, channel, profit_rank
