WITH full_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_item_id,
        i.i_category_id,
        i.i_category
    FROM catalog_sales cs
    FULL OUTER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
),
sub_a AS (
    SELECT
        cs_order_number,
        cs_quantity,
        cs_net_paid,
        i_item_id,
        i_category_id,
        i_category
    FROM full_join
    WHERE cs_quantity > 5 AND i_category_id = 3
),
sub_b AS (
    SELECT
        cs_order_number,
        cs_quantity,
        cs_net_paid,
        i_item_id,
        i_category_id,
        i_category
    FROM full_join
    WHERE cs_quantity <= 5 AND i_category_id = 1
),
unioned AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
),
anti_filtered AS (
    SELECT *
    FROM unioned u
    WHERE cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity > 1000
    )
)
SELECT
    cs_order_number,
    cs_quantity,
    cs_net_paid,
    i_item_id,
    i_category_id,
    i_category,
    ROW_NUMBER() OVER (ORDER BY cs_quantity DESC) AS rn
FROM anti_filtered
ORDER BY rn ASC
LIMIT 100
