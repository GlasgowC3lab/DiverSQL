SELECT
    s.s_store_id,
    s.s_store_name,
    concat_ws(', ', s.s_city, s.s_state, s.s_zip) AS store_location,
    length(s.s_store_name) AS store_name_len,
    lower(s.s_store_name) AS store_name_lower,
    upper(s.s_store_name) AS store_name_upper,
    substr(s.s_store_name, 1, 3) AS store_name_prefix,
    reverse(s.s_store_name) AS reversed_store_name,
    regexp_replace(s.s_store_name, '\\b(.)\\w*\\b', '\\1') AS store_name_abbr,
    trim(both ' ' FROM s.s_hours) AS trimmed_hours,
    regexp_replace(s.s_hours, '[^0-9]', '') AS hours_numeric,
    CASE WHEN regexp_like(s.s_manager, '(?i)smith') THEN 1 ELSE 0 END AS manager_has_smith,
    lower(s.s_manager) AS manager_lower,
    concat_ws(' - ', s.s_manager, coalesce(c.c_email_address, 'noemail')) AS manager_contact,
    format('Store %d: %s', s.s_store_sk, s.s_store_name) AS formatted_store_desc,
    count(ss.ss_ticket_number) AS total_transactions,
    count(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(ss.ss_net_paid) AS total_net_paid,
    avg(ss.ss_quantity) AS avg_quantity,
    sum(ss.ss_quantity * ss.ss_sales_price) / nullif(sum(ss.ss_quantity), 0) AS avg_price_per_item,
    array_agg(DISTINCT i.i_product_name) FILTER (WHERE i.i_product_name IS NOT NULL) AS product_names,
    cardinality(array_agg(DISTINCT i.i_product_name)) AS distinct_product_count,
    concat_ws('|', array_sort(array_agg(DISTINCT i.i_color))) AS sorted_colors,
    max(length(i.i_item_desc)) AS max_desc_len,
    sum(length(i.i_item_desc)) AS total_desc_len,
    sum(regexp_count(i.i_item_desc, '\\s+') + 1) AS total_words_desc,
    avg(length(i.i_item_desc) - length(regexp_replace(i.i_item_desc, '\\s+', ''))) AS avg_spaces_in_desc,
    max(substring(i.i_item_desc, 1, 20)) AS item_desc_prefix,
    min(split_part(i.i_item_desc, ' ', 1)) AS first_word_desc,
    max(replace(i.i_item_desc, ' ', '_')) AS desc_underscored,
    avg(length(trim(i.i_item_desc))) AS avg_trimmed_desc_len,
    sum(CASE WHEN regexp_like(i.i_item_desc, '(?i)\\bpremium\\b') THEN 1 ELSE 0 END) AS premium_desc_count,
    d.d_year,
    d.d_month_seq
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE s.s_state IN ('CA', 'NY', 'TX')
  AND i.i_color IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_zip,
    s.s_hours,
    s.s_manager,
    s.s_store_sk,
    c.c_email_address,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 10
