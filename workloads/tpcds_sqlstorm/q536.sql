WITH cat_sales AS (
   SELECT
     cs.cs_order_number AS order_number,
     cs.cs_net_paid AS net_paid,
     dd.d_date,
     c.c_first_name,
     c.c_last_name,
     i.i_item_desc,
     cc.cc_name AS channel_info,
     'catalog' AS sales_channel
   FROM catalog_sales cs
   JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE cs.cs_sold_date_sk IS NOT NULL
),
web_sales_cte AS (
   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_net_paid AS net_paid,
     dd.d_date,
     c.c_first_name,
     c.c_last_name,
     i.i_item_desc,
     wp.wp_url AS channel_info,
     'web' AS sales_channel
   FROM web_sales ws
   JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE ws.ws_sold_date_sk IS NOT NULL
),
store_sales_cte AS (
   SELECT
     ss.ss_ticket_number AS order_number,
     ss.ss_net_paid AS net_paid,
     dd.d_date,
     c.c_first_name,
     c.c_last_name,
     i.i_item_desc,
     s.s_store_name AS channel_info,
     'store' AS sales_channel
   FROM store_sales ss
   JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_sold_date_sk IS NOT NULL
),
union_sales AS (
   SELECT * FROM cat_sales
   UNION ALL
   SELECT * FROM web_sales_cte
   UNION ALL
   SELECT * FROM store_sales_cte
),
base_sales AS (
   SELECT
     d_date,
     sales_channel,
     net_paid,
     order_number,
     c_first_name,
     c_last_name,
     i_item_desc,
     channel_info,
     lower(regexp_replace(c_first_name || '_' || c_last_name, '\\s+', '')) AS cust_name_clean,
     substr(regexp_replace(i_item_desc, '\\s+', ''), 1, 10) AS desc_snippet,
     CASE
       WHEN sales_channel = 'catalog' THEN lower(regexp_replace(channel_info, '\\s+', '_'))
       WHEN sales_channel = 'web' THEN lower(regexp_extract(channel_info, 'https?://([^/]+)/', 1))
       WHEN sales_channel = 'store' THEN lower(regexp_replace(channel_info, '\\s+', '_'))
       ELSE lower(regexp_replace(channel_info, '\\s+', '_'))
     END AS channel_clean,
     regexp_extract(CAST(order_number AS varchar), '(\\d{4})$') AS order_suffix
   FROM union_sales
),
final_sales AS (
   SELECT
     d_date,
     sales_channel,
     net_paid,
     order_number,
     cust_name_clean,
     desc_snippet,
     channel_clean,
     order_suffix,
     concat_ws('_', cust_name_clean, desc_snippet, channel_clean, order_suffix) AS composite_key,
     length(concat_ws('_', cust_name_clean, desc_snippet, channel_clean, order_suffix)) AS composite_key_len
   FROM base_sales
)
SELECT
  d_date,
  sales_channel,
  count(*) AS order_count,
  sum(net_paid) AS total_paid,
  avg(composite_key_len) AS avg_key_len,
  array_join(
    slice(
      array_agg(composite_key ORDER BY composite_key_len DESC),
      1,
      5
    ),
    ', '
  ) AS top_5_keys
FROM final_sales
GROUP BY d_date, sales_channel
ORDER BY total_paid DESC
LIMIT 100
