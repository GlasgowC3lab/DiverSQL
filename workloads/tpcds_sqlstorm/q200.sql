WITH web_agg AS (
   SELECT
      d.d_year AS sales_year,
      ca.ca_state AS state,
      i.i_category AS category,
      i.i_class AS class,
      'Web' AS channel,
      SUM(ws.ws_quantity) AS total_quantity,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_paid) AS net_paid,
      SUM(ws.ws_net_profit) AS net_profit,
      SUM(ws.ws_ext_discount_amt) AS discount_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY d.d_year, ca.ca_state, i.i_category, i.i_class
),
store_agg AS (
   SELECT
      d.d_year AS sales_year,
      ca.ca_state AS state,
      i.i_category AS category,
      i.i_class AS class,
      'Store' AS channel,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_paid) AS net_paid,
      SUM(ss.ss_net_profit) AS net_profit,
      SUM(ss.ss_ext_discount_amt) AS discount_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY d.d_year, ca.ca_state, i.i_category, i.i_class
),
catalog_agg AS (
   SELECT
      d.d_year AS sales_year,
      ca.ca_state AS state,
      i.i_category AS category,
      i.i_class AS class,
      'Catalog' AS channel,
      SUM(cs.cs_quantity) AS total_quantity,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_paid) AS net_paid,
      SUM(cs.cs_net_profit) AS net_profit,
      SUM(cs.cs_ext_discount_amt) AS discount_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY d.d_year, ca.ca_state, i.i_category, i.i_class
),
combined AS (
   SELECT * FROM web_agg
   UNION ALL
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM catalog_agg
)
SELECT
   sales_year,
   state,
   channel,
   category,
   class,
   total_quantity,
   total_sales,
   net_paid,
   net_profit,
   discount_amount,
   discount_pct,
   profit_rank
FROM (
   SELECT
      sales_year,
      state,
      channel,
      category,
      class,
      total_quantity,
      total_sales,
      net_paid,
      net_profit,
      discount_amount,
      ROUND(100.0 * discount_amount / NULLIF(total_sales, 0), 2) AS discount_pct,
      RANK() OVER (PARTITION BY sales_year, channel ORDER BY net_profit DESC) AS profit_rank
   FROM (
      SELECT
         sales_year,
         state,
         channel,
         category,
         class,
         SUM(total_quantity) AS total_quantity,
         SUM(total_sales) AS total_sales,
         SUM(net_paid) AS net_paid,
         SUM(net_profit) AS net_profit,
         SUM(discount_amount) AS discount_amount
      FROM combined
      GROUP BY sales_year, state, channel, category, class
   ) agg
) ranked
WHERE profit_rank <= 5
ORDER BY sales_year, channel, profit_rank
