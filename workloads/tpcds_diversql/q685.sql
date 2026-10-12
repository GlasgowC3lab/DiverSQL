WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk
),
intersect_items AS (
    SELECT p_item_sk
    FROM (
        SELECT p_item_sk
        FROM promotion
        WHERE p_discount_active = 'Y'
          AND p_cost > 1000
          AND p_channel_email = 'Y'
    )
    INTERSECT
    SELECT sr_item_sk
    FROM store_returns
    WHERE sr_return_amt > 50
      AND sr_return_quantity >= 1
)
SELECT
    i.i_brand,
    cd.cd_gender,
    p.p_promo_name,
    SUM(adj.adjusted_return) AS total_adj_return,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_return_amt,
    CASE
        WHEN SUM(adj.adjusted_return) > 5000 THEN 'High'
        ELSE 'Normal'
    END AS return_level
FROM intersect_items ii
JOIN item i
    ON ii.p_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN inv_agg inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT (sr.sr_return_amt_inc_tax - sr.sr_return_tax) *
           CASE WHEN sr.sr_store_credit > 20 THEN 1.1 ELSE 1 END AS adjusted_return
) AS adj ON TRUE
WHERE i.i_current_price BETWEEN 10 AND 100
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_count <= 3
  AND inv.total_qty_on_hand > 500
  AND p.p_promo_name IS NOT NULL
GROUP BY CUBE (i.i_brand, cd.cd_gender, p.p_promo_name)
HAVING SUM(adj.adjusted_return) > 1000
ORDER BY total_adj_return DESC
LIMIT 100
