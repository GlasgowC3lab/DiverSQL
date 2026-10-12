WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND regexp_like(p.p_promo_name, '^PROMO[0-9]{3}$')
        AND i.i_item_desc LIKE '%steel%'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_item_sk = cs.cs_item_sk
        )
),
agg_sales AS (
    SELECT
        bs.i_item_id,
        bs.i_item_desc,
        bs.p_promo_name,
        ld.first_word,
        SUM(bs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM
        base_sales bs
        CROSS JOIN LATERAL (
            SELECT regexp_extract(bs.i_item_desc, '^(\\w+)', 1) AS first_word
        ) ld
    GROUP BY
        bs.i_item_id,
        bs.i_item_desc,
        bs.p_promo_name,
        ld.first_word
),
final_sales AS (
    SELECT
        a.i_item_id,
        a.i_item_desc,
        a.p_promo_name,
        a.first_word,
        a.total_net_paid,
        a.sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY a.total_net_paid DESC) AS rn
    FROM
        agg_sales a
)
SELECT
    i_item_id,
    i_item_desc,
    p_promo_name,
    first_word,
    total_net_paid,
    sales_cnt,
    rn
FROM
    final_sales
ORDER BY
    total_net_paid DESC
LIMIT 100
