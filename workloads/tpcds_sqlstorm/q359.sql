WITH sale_strings AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        d.d_date,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_product_name,
        p.p_promo_name,
        trim(s.s_store_name) AS trimmed_store_name,
        substr(trim(s.s_store_name), 1, 3) AS store_abbrev,
        format('%s, %s', s.s_city, s.s_state) AS city_state,
        lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')) AS clean_store_name,
        replace(i.i_product_name, ' ', '-') AS clean_item_name,
        regexp_replace(p.p_promo_name, '\\s+', ' ') AS norm_promo_name,
        concat_ws(' | ',
            lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
            replace(i.i_product_name, ' ', '-'),
            regexp_replace(p.p_promo_name, '\\s+', ' '),
            CAST(d.d_date AS varchar)
        ) AS full_desc,
        length(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            )
        ) AS full_desc_len,
        regexp_like(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            ),
            'promo'
        ) AS has_promo_word,
        length(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            )
        ) - length(
            replace(
                concat_ws(' | ',
                    lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                    replace(i.i_product_name, ' ', '-'),
                    regexp_replace(p.p_promo_name, '\\s+', ' '),
                    CAST(d.d_date AS varchar)
                ),
                '|',
                ''
            )
        ) AS pipe_count,
        substr(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            ),
            1,
            10
        ) AS snippet,
        reverse(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            )
        ) AS rev_full_desc,
        strpos(
            concat_ws(' | ',
                lower(regexp_replace(s.s_store_name, '[^a-z0-9]', '')),
                replace(i.i_product_name, ' ', '-'),
                regexp_replace(p.p_promo_name, '\\s+', ' '),
                CAST(d.d_date AS varchar)
            ),
            '|'
        ) AS first_pipe_pos,
        cardinality(split(i.i_product_name, ' ')) AS product_word_count,
        element_at(split(i.i_product_name, ' '), 1) AS product_first_word
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT
        s_store_name,
        s_city,
        s_state,
        COUNT(*) AS sales_cnt,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(full_desc_len) AS avg_desc_len,
        MAX(full_desc_len) AS max_desc_len,
        SUM(CASE WHEN has_promo_word THEN 1 ELSE 0 END) AS promo_word_cnt,
        AVG(pipe_count) AS avg_pipe_count,
        MIN(snippet) AS min_snippet,
        MAX(rev_full_desc) AS max_rev_desc,
        AVG(first_pipe_pos) AS avg_first_pipe_pos,
        AVG(product_word_count) AS avg_product_word_cnt,
        MIN(product_first_word) AS lexicographically_smallest_product_word
    FROM sale_strings
    GROUP BY s_store_name, s_city, s_state
)
SELECT
    s_store_name,
    s_city,
    s_state,
    sales_cnt,
    total_net_paid,
    avg_desc_len,
    max_desc_len,
    promo_word_cnt,
    avg_pipe_count,
    min_snippet,
    max_rev_desc,
    avg_first_pipe_pos,
    avg_product_word_cnt,
    lexicographically_smallest_product_word,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 10
