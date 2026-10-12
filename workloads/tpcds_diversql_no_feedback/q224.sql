WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_ext_tax,
        i.i_brand,
        i.i_color,
        i.i_units,
        i.i_formulation,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        cs.cs_ext_tax > 20
        AND regexp_like(i.i_color, '^p.*')
        AND i.i_units LIKE '%Case%'
),
aggregated AS (
    SELECT
        i_brand AS brand,
        i_color AS color,
        formulation_number,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_ext_discount_amt) AS avg_discount
    FROM filtered_sales
    GROUP BY i_brand, i_color, formulation_number
),
ranked AS (
    SELECT
        brand,
        color,
        formulation_number,
        total_profit,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY color ORDER BY total_profit DESC) AS rnk
    FROM aggregated
)
SELECT
    brand,
    color,
    formulation_number,
    total_profit,
    avg_discount
FROM ranked
WHERE rnk <= 5
ORDER BY color, rnk
