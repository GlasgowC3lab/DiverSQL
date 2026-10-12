WITH unified_sales AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'store' AS channel,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    concat_ws(' | ', s.s_store_name, i.i_product_name, i.i_brand, i.i_category) AS combined_string,
    length(concat_ws(' | ', s.s_store_name, i.i_product_name, i.i_brand, i.i_category)) AS combined_len,
    cardinality(split(i.i_product_name, ' ')) AS product_word_cnt,
    regexp_replace(lower(i.i_product_name), '[^aeiou]', '') AS vow_string
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002

  UNION ALL

  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'catalog' AS channel,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    concat_ws(' | ', cp.cp_department, cp.cp_description, i.i_product_name, i.i_brand) AS combined_string,
    length(concat_ws(' | ', cp.cp_department, cp.cp_description, i.i_product_name, i.i_brand)) AS combined_len,
    cardinality(split(i.i_product_name, ' ')) AS product_word_cnt,
    regexp_replace(lower(i.i_product_name), '[^aeiou]', '') AS vow_string
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002

  UNION ALL

  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    'web' AS channel,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    concat_ws(' | ', wp.wp_url, i.i_product_name, i.i_brand) AS combined_string,
    length(concat_ws(' | ', wp.wp_url, i.i_product_name, i.i_brand)) AS combined_len,
    cardinality(split(i.i_product_name, ' ')) AS product_word_cnt,
    regexp_replace(lower(i.i_product_name), '[^aeiou]', '') AS vow_string
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
), combined_counts AS (
  SELECT
    year,
    month_seq,
    channel,
    combined_string,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (PARTITION BY year, month_seq, channel ORDER BY COUNT(*) DESC, combined_string) AS rn
  FROM unified_sales
  GROUP BY year, month_seq, channel, combined_string
)
SELECT
  us.year,
  us.month_seq,
  us.channel,
  SUM(us.net_paid) AS total_net_paid,
  SUM(us.net_profit) AS total_net_profit,
  AVG(us.combined_len) AS avg_combined_len,
  AVG(us.product_word_cnt) AS avg_product_word_cnt,
  AVG(LENGTH(us.vow_string)) AS avg_vowel_count_in_product,
  cc.combined_string AS top_combined_string
FROM unified_sales us
JOIN combined_counts cc
  ON us.year = cc.year
  AND us.month_seq = cc.month_seq
  AND us.channel = cc.channel
  AND cc.rn = 1
GROUP BY us.year, us.month_seq, us.channel, cc.combined_string
ORDER BY us.year, us.month_seq, us.channel
