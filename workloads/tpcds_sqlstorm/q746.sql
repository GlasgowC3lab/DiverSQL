WITH base AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_paid,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_login,
        i.i_product_name,
        i.i_color,
        s.s_store_name,
        p.p_promo_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    COUNT(*) AS txn_count,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(length(c_first_name)) AS avg_first_name_len,
    AVG(length(c_last_name)) AS avg_last_name_len,
    AVG(length(c_email_address)) AS avg_email_len,
    COUNT(DISTINCT regexp_extract(c_email_address, '@([^.]*)', 1)) AS distinct_email_domains,
    SUM(CASE WHEN regexp_like(c_login, '^admin') THEN 1 ELSE 0 END) AS admin_login_cnt,
    AVG(cardinality(split(c_login, '\\.'))) AS avg_login_parts,
    AVG(length(regexp_replace(i_product_name, '[^A-Za-z0-9]', ''))) AS avg_clean_product_name_len,
    SUM(CASE WHEN i_color = upper(i_color) THEN 1 ELSE 0 END) AS all_uppercase_color_cnt,
    SUM(CASE WHEN i_color = lower(i_color) THEN 1 ELSE 0 END) AS all_lowercase_color_cnt,
    AVG(length(regexp_replace(s_store_name, '\\s+', ''))) AS avg_clean_store_name_len,
    COUNT(DISTINCT p_promo_name) AS distinct_promo_names
FROM base
GROUP BY s_store_name, d_year, d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
