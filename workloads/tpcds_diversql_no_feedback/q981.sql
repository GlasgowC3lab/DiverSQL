WITH sales_returns AS (
    SELECT
        i.i_category,
        p.p_channel_email,
        MAX(substr(i.i_product_name, 1, 5)) AS prod_prefix,
        MAX(regexp_extract(i.i_product_name, '(\\w+)', 1)) AS first_word,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    WHERE regexp_like(i.i_product_name, 'ough')
      AND p.p_promo_name LIKE '%Sale%'
    GROUP BY GROUPING SETS (
        (i.i_category, p.p_channel_email),
        (i.i_category),
        (p.p_channel_email)
    )
)
SELECT
    i_category,
    p_channel_email,
    prod_prefix,
    first_word,
    total_net_profit,
    total_return_amount
FROM sales_returns
ORDER BY total_net_profit DESC
LIMIT 100
