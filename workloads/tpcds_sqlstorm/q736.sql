WITH sales_all AS (
    SELECT
        cs.cs_sold_date_sk AS sales_date_sk,
        'catalog' AS sales_channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_item_sk AS product_sk,
        CAST(NULL AS integer) AS store_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        'store',
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_item_sk,
        ss.ss_store_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        'web',
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_item_sk,
        CAST(NULL AS integer)
    FROM web_sales ws
),
product_info AS (
    SELECT
        sa.sales_date_sk,
        sa.sales_channel,
        sa.quantity,
        sa.net_paid,
        sa.store_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        i.i_brand,
        i.i_category,
        i.i_manufact
    FROM sales_all sa
    JOIN item i ON sa.product_sk = i.i_item_sk
),
store_info AS (
    SELECT
        pi.*,
        s.s_store_name
    FROM product_info pi
    LEFT JOIN store s ON pi.store_sk = s.s_store_sk
),
date_info AS (
    SELECT
        si.*,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM store_info si
    JOIN date_dim d ON si.sales_date_sk = d.d_date_sk
)
SELECT
    sales_channel,
    d_year,
    d_month_seq,
    COALESCE(s_store_name, 'UNKNOWN') AS store_name,
    sum(net_paid) AS total_net_paid,
    sum(quantity) AS total_quantity,
    length(
        regexp_replace(
            lower(
                concat_ws('|',
                    sales_channel,
                    cast(d_year as varchar),
                    cast(d_month_seq as varchar),
                    COALESCE(s_store_name, ''),
                    i_item_id,
                    i_product_name,
                    i_item_desc,
                    COALESCE(i_color, ''),
                    COALESCE(i_size, ''),
                    COALESCE(i_brand, ''),
                    COALESCE(i_category, ''),
                    COALESCE(i_manufact, '')
                )
            ),
            '[^a-z0-9|]',
            ''
        )
    ) AS clean_string_len,
    cardinality(
        split(
            regexp_replace(
                lower(
                    concat_ws('|',
                        sales_channel,
                        cast(d_year as varchar),
                        cast(d_month_seq as varchar),
                        COALESCE(s_store_name, ''),
                        i_item_id,
                        i_product_name,
                        i_item_desc,
                        COALESCE(i_color, ''),
                        COALESCE(i_size, ''),
                        COALESCE(i_brand, ''),
                        COALESCE(i_category, ''),
                        COALESCE(i_manufact, '')
                    )
                ),
                '[^a-z0-9|]',
                ''
            ),
            '\|'
        )
    ) AS token_count,
    reverse(
        regexp_replace(
            lower(
                concat_ws('|',
                    sales_channel,
                    cast(d_year as varchar),
                    cast(d_month_seq as varchar),
                    COALESCE(s_store_name, ''),
                    i_item_id,
                    i_product_name,
                    i_item_desc,
                    COALESCE(i_color, ''),
                    COALESCE(i_size, ''),
                    COALESCE(i_brand, ''),
                    COALESCE(i_category, ''),
                    COALESCE(i_manufact, '')
                )
            ),
            '[^a-z0-9|]',
            ''
        )
    ) AS reversed_clean_string
FROM date_info
GROUP BY
    sales_channel,
    d_year,
    d_month_seq,
    s_store_name,
    i_item_id,
    i_product_name,
    i_item_desc,
    i_color,
    i_size,
    i_brand,
    i_category,
    i_manufact
