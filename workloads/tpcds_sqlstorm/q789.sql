SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    sum(ss.ss_net_paid) AS store_net_paid,
    sum(ws.ws_net_paid) AS web_net_paid,
    round(
        sum(ss.ss_net_paid) / nullif(sum(ws.ws_net_paid), 0),
        2
    ) AS store_to_web_ratio,
    count(DISTINCT ss.ss_item_sk) AS distinct_store_items,
    count(DISTINCT ws.ws_item_sk) AS distinct_web_items,
    avg(length(i.i_product_name)) AS avg_product_name_len,
    max(length(i.i_product_name)) AS max_product_name_len,
    min(length(i.i_product_name)) AS min_product_name_len,
    any_value(regexp_replace(lower(i.i_product_name), '[^a-z0-9]', '')) AS cleaned_product_name,
    any_value(substr(i.i_product_name, 1, 5)) AS product_name_prefix,
    any_value(regexp_extract(i.i_product_name, '(\\w+)\\s+(\\w+)', 2)) AS second_word,
    concat_ws(' - ', s.s_city, s.s_state, any_value(i.i_color)) AS location_color,
    replace(any_value(s.s_hours), ':', '-') AS sanitized_store_hours,
    format('Store %s (%s) sold %d items in %d', s.s_store_id, s.s_store_name, count(ss.ss_item_sk), d.d_year) AS summary,
    array_join(
        array_agg(DISTINCT lower(regexp_replace(wp.wp_url, 'https?://', ''))),
        ', '
    ) AS cleaned_web_urls,
    any_value(split_part(wp.wp_url, '/', 3)) AS domain,
    any_value(strpos(wp.wp_url, '://')) AS protocol_position
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
    AND ws.ws_item_sk = ss.ss_item_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND i.i_product_name IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    s.s_city,
    s.s_state
HAVING sum(ss.ss_net_paid) > 0
ORDER BY store_net_paid DESC
LIMIT 50
