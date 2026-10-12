WITH cust_info AS (
    SELECT c.c_customer_sk,
           concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
           lower(c.c_email_address) AS email_lc,
           regexp_replace(c.c_email_address, '@.*', '@masked.com') AS email_masked,
           CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_status,
           concat_ws(', ', concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type), ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT ss.ss_customer_sk,
           ss.ss_ticket_number,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           i.i_item_sk AS i_item_sk,
           i.i_product_name,
           i.i_color,
           i.i_size,
           concat_ws(' - ', i.i_product_name, i.i_color, i.i_size) AS product_desc,
           lower(i.i_product_name) AS product_name_lc,
           length(i.i_product_name) AS product_name_len,
           substr(i.i_product_name, 1, 5) AS product_prefix,
           substr(i.i_product_name, length(i.i_product_name) - 4, 5) AS product_suffix,
           regexp_replace(i.i_product_name, '\\s+', ' ') AS product_single_space,
           regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS product_alnum,
           replace(i.i_product_name, ' ', '_') AS product_underscore,
           split(i.i_product_name, ' ') AS product_words,
           cardinality(split(i.i_product_name, ' ')) AS word_count,
           array_join(regexp_extract_all(i.i_product_name, '([A-Z])', 1), '') AS product_initials,
           CASE WHEN i.i_color IS NOT NULL THEN 'Color_' || i.i_color ELSE 'NoColor' END AS color_flag,
           regexp_like(i.i_product_name, '\\d{3}') AS has_three_digits
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
word_counts AS (
    SELECT sd.ss_customer_sk AS customer_sk,
           w AS word,
           count(*) AS word_freq
    FROM sales_data sd
    CROSS JOIN UNNEST(sd.product_words) AS t (w)
    WHERE w <> ''
    GROUP BY sd.ss_customer_sk, w
),
top_words AS (
    SELECT wc.customer_sk,
           array_join(slice(array_agg(wc.word ORDER BY wc.word_freq DESC), 1, 5), ',') AS top_5_words,
           max(wc.word_freq) AS max_word_freq
    FROM word_counts wc
    GROUP BY wc.customer_sk
)
SELECT ci.full_name,
       reverse(ci.full_name) AS reversed_name,
       ci.email_masked,
       ci.full_address,
       ci.cust_status,
       upper(ci.cust_status) AS cust_status_upper,
       count(sd.ss_ticket_number) AS total_orders,
       sum(sd.ss_net_paid) AS total_spent,
       avg(sd.product_name_len) AS avg_product_name_length,
       max(sd.product_name_len) AS max_product_name_length,
       sum(CASE WHEN sd.has_three_digits THEN sd.ss_net_paid ELSE 0 END) AS spent_on_items_with_digits,
       count(DISTINCT sd.i_item_sk) AS distinct_items_bought,
       tw.top_5_words,
       tw.max_word_freq
FROM cust_info ci
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ss_customer_sk
LEFT JOIN top_words tw ON ci.c_customer_sk = tw.customer_sk
GROUP BY ci.full_name,
         reverse(ci.full_name),
         ci.email_masked,
         ci.full_address,
         ci.cust_status,
         upper(ci.cust_status),
         tw.top_5_words,
         tw.max_word_freq
ORDER BY total_spent DESC
LIMIT 100
