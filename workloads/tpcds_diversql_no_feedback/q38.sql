WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        substr(i.i_brand, 1, 3) AS brand_prefix,
        regexp_extract(i.i_item_desc, '(\\w+)$', 1) AS last_word_desc
    FROM
        tpcds.item i
    WHERE
        regexp_like(i.i_item_desc, '(?i)political|classical')
        AND i.i_brand LIKE '%brand #%'
),
joined_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        d.d_date,
        fi.i_category,
        fi.i_brand,
        fi.brand_prefix,
        fi.last_word_desc,
        ROW_NUMBER() OVER (PARTITION BY fi.i_category ORDER BY cr.cr_return_amount DESC) AS rn
    FROM
        tpcds.catalog_returns cr
        JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr
            WHERE wr.wr_item_sk = cr.cr_item_sk
              AND wr.wr_returned_date_sk = cr.cr_returned_date_sk
        )
)
SELECT
    jr.d_year,
    jr.d_date,
    jr.i_category,
    jr.i_brand,
    jr.brand_prefix,
    jr.last_word_desc,
    jr.cr_return_quantity,
    jr.cr_return_amount,
    jr.cr_net_loss
FROM
    joined_returns jr
WHERE
    jr.rn <= 5
ORDER BY
    jr.i_category,
    jr.cr_return_amount DESC
LIMIT 100
