WITH sales_union AS (
 SELECT ss_sold_date_sk AS date_sk,
        ss_store_sk AS location_sk,
        ss_customer_sk AS customer_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_sales_price AS unit_price,
        ss_ext_sales_price AS ext_sales_price,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        'store' AS channel
 FROM store_sales
 UNION ALL
 SELECT cs_sold_date_sk,
        cs_call_center_sk,
        cs_bill_customer_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        cs_net_paid,
        cs_net_profit,
        'catalog' AS channel
 FROM catalog_sales
 UNION ALL
 SELECT ws_sold_date_sk,
        ws_warehouse_sk,
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_paid,
        ws_net_profit,
        'web' AS channel
 FROM web_sales
),
sales_enriched AS (
 SELECT s.*,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_state,
        CASE 
          WHEN s.channel = 'store' THEN st.s_store_name
          WHEN s.channel = 'catalog' THEN cc.cc_name
          WHEN s.channel = 'web' THEN w.w_warehouse_name
          ELSE NULL
        END AS location_name
 FROM sales_union s
 LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
 LEFT JOIN item i ON s.item_sk = i.i_item_sk
 LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
 LEFT JOIN store st ON s.channel = 'store' AND s.location_sk = st.s_store_sk
 LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.location_sk = cc.cc_call_center_sk
 LEFT JOIN warehouse w ON s.channel = 'web' AND s.location_sk = w.w_warehouse_sk
),
sales_agg AS (
 SELECT 
   d_year,
   i_category,
   i_class,
   i_brand,
   channel,
   location_name,
   SUM(quantity) AS total_quantity,
   SUM(ext_sales_price) AS total_sales,
   SUM(net_profit) AS total_profit,
   COUNT(DISTINCT customer_sk) AS unique_customers
 FROM sales_enriched
 GROUP BY d_year, i_category, i_class, i_brand, channel, location_name
),
ranked_sales AS (
 SELECT 
   *,
   ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_sales DESC) AS sales_rank
 FROM sales_agg
)
SELECT 
  d_year,
  i_category,
  i_class,
  i_brand,
  channel,
  location_name,
  total_quantity,
  total_sales,
  total_profit,
  unique_customers,
  sales_rank
FROM ranked_sales
WHERE sales_rank <= 10
ORDER BY d_year DESC, total_sales DESC
LIMIT 200
