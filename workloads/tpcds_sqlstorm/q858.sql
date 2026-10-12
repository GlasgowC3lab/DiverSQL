WITH
   item_desc_processed AS (
      SELECT i_item_sk,
             lower(i_product_name) AS product_name_lower,
             regexp_replace(i_product_name, '[^a-zA-Z0-9]', '') AS product_name_alnum,
             length(i_product_name) AS product_name_len,
             cardinality(split(i_product_name, ' ')) AS word_count,
             substr(i_product_name, 1, 10) AS product_name_prefix,
             substr(i_product_name, -10) AS product_name_suffix
      FROM item
   ),
   combined_sales AS (
      SELECT 'store' AS sales_channel,
             ss.ss_sold_date_sk AS sold_date_sk,
             ss.ss_item_sk AS item_sk,
             ss.ss_quantity AS quantity,
             ss.ss_net_paid AS net_paid,
             ss.ss_ticket_number AS ticket_number
      FROM store_sales ss
      UNION ALL
      SELECT 'web' AS sales_channel,
             ws.ws_sold_date_sk AS sold_date_sk,
             ws.ws_item_sk AS item_sk,
             ws.ws_quantity AS quantity,
             ws.ws_net_paid AS net_paid,
             ws.ws_order_number AS ticket_number
      FROM web_sales ws
      UNION ALL
      SELECT 'catalog' AS sales_channel,
             cs.cs_sold_date_sk AS sold_date_sk,
             cs.cs_item_sk AS item_sk,
             cs.cs_quantity AS quantity,
             cs.cs_net_paid AS net_paid,
             cs.cs_order_number AS ticket_number
      FROM catalog_sales cs
   ),
   sales_with_desc AS (
      SELECT cs.sales_channel,
             d.d_year,
             id.product_name_lower,
             id.product_name_alnum,
             id.product_name_len,
             id.word_count,
             id.product_name_prefix,
             id.product_name_suffix,
             cs.quantity,
             cs.net_paid,
             cs.ticket_number,
             concat(id.product_name_prefix, '-', cs.sales_channel) AS composite_key,
             regexp_like(id.product_name_alnum, '[0-9]') AS contains_digit,
             replace(id.product_name_lower, ' ', '_') AS product_name_underscore,
             concat_ws('|', id.product_name_lower, cs.sales_channel) AS label
      FROM combined_sales cs
      JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
      JOIN item_desc_processed id ON cs.item_sk = id.i_item_sk
   )
SELECT
   sales_channel,
   d_year,
   substring(product_name_lower, 1, 5) AS product_name_5char,
   upper(product_name_prefix) AS product_name_prefix_upper,
   length(product_name_underscore) AS product_name_underscore_len,
   word_count,
   sum(quantity) AS total_qty,
   sum(net_paid) AS total_net_paid,
   avg(net_paid / quantity) AS avg_price_per_item,
   count(DISTINCT ticket_number) AS distinct_transactions,
   approx_percentile(net_paid, 0.5) AS median_net_paid,
   array_join(array_agg(DISTINCT substring(product_name_lower, 1, 5)), ',') AS distinct_5char_codes
FROM sales_with_desc
WHERE contains_digit
GROUP BY
   sales_channel,
   d_year,
   substring(product_name_lower, 1, 5),
   upper(product_name_prefix),
   length(product_name_underscore),
   word_count
ORDER BY total_net_paid DESC
LIMIT 100
