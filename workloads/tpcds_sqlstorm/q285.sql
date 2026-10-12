SELECT
  d.d_year AS year,
  word,
  COUNT(*) AS occurrences,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  ROUND(AVG(LENGTH(i.i_item_desc)), 2) AS avg_desc_len,
  MAX(LENGTH(s.s_store_name)) AS max_store_name_len
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
CROSS JOIN UNNEST(
  split(
    regexp_replace(
      lower(
        concat(
          COALESCE(i.i_product_name, ''),
          ' ',
          COALESCE(i.i_item_desc, ''),
          ' ',
          COALESCE(s.s_store_name, ''),
          ' ',
          COALESCE(s.s_city, '')
        )
      ),
      '[^a-z0-9]+',
      ' '
    ),
    ' '
  )
) AS t(word)
WHERE d.d_year BETWEEN 1998 AND 2002
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND length(word) > 2
GROUP BY d.d_year, word
HAVING COUNT(*) > 100
ORDER BY d.d_year, occurrences DESC
LIMIT 100
