WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_zip,
        s.s_gmt_offset,
        i.i_item_sk,
        i.i_product_name,
        i.i_color,
        i.i_size,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_year,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
transformed AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        concat_ws('_',
            lower(substr(s_store_name, 1, 5)),
            reverse(lower(s_city)),
            substr(split(s_zip, '-')[1], 1, 5),
            format('%03d', CAST(s_gmt_offset * 100 AS integer))) AS store_sig,
        concat_ws('|',
            replace(regexp_replace(i_product_name, '[^A-Za-z0-9 ]', ''), ' ', '_'),
            lower(i_color),
            upper(i_size)) AS prod_sig,
        concat_ws('#',
            lower(c_first_name),
            upper(c_last_name),
            substr(c_email_address, 1, 3),
            CAST(c_birth_year AS varchar)) AS cust_sig,
        ss_quantity,
        ss_net_paid,
        ss_net_profit,
        c_customer_sk,
        length(i_product_name) AS prod_name_len,
        length(regexp_replace(i_product_name, '\\s+', '')) AS prod_name_no_spaces_len
    FROM sales
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        store_sig,
        array_join(array_agg(DISTINCT prod_sig), ',') AS prod_sig_list,
        array_join(array_agg(DISTINCT cust_sig), ',') AS cust_sig_list,
        COUNT(*) AS trans_cnt,
        SUM(ss_quantity) AS total_qty,
        SUM(ss_net_paid) AS total_paid,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        max(prod_name_len) AS max_prod_name_len,
        avg(prod_name_no_spaces_len) AS avg_prod_name_no_spaces_len
    FROM transformed
    GROUP BY d_year, d_month_seq, s_store_sk, store_sig
)
SELECT
    d_year,
    d_month_seq,
    s_store_sk,
    store_sig,
    prod_sig_list,
    cust_sig_list,
    trans_cnt,
    total_qty,
    total_paid,
    total_profit,
    distinct_customers,
    max_prod_name_len,
    avg_prod_name_no_spaces_len,
    CASE
        WHEN regexp_like(store_sig, '^a.*') THEN 'GroupA'
        WHEN regexp_like(store_sig, '^b.*') THEN 'GroupB'
        ELSE 'OtherGroup'
    END AS store_group,
    CASE
        WHEN length(prod_sig_list) > 100 THEN substr(prod_sig_list, 1, 100) || '...'
        ELSE prod_sig_list
    END AS prod_sig_list_trunc,
    CASE
        WHEN lower(cust_sig_list) LIKE '%john%' THEN 'ContainsJohn'
        ELSE 'NoJohn'
    END AS cust_flag
FROM agg
ORDER BY total_profit DESC
LIMIT 100
