WITH web_sales_agg AS (
    SELECT i.i_item_sk            AS item_sk,
           i.i_item_id            AS item_id,
           i.i_rec_start_date     AS reference_date,
           SUM(ws.ws_ext_sales_price) AS total_amount,
           'web'                  AS src
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_brand_id = 1001001
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_rec_start_date
),
store_returns_agg AS (
    SELECT i.i_item_sk            AS item_sk,
           i.i_item_id            AS item_id,
           i.i_rec_start_date     AS reference_date,
           SUM(sr.sr_return_amt)  AS total_amount,
           'store'                AS src
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_brand_id = 1001001
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_rec_start_date
),
combined AS (
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
)
SELECT c.item_sk,
       c.item_id,
       c.reference_date,
       c.total_amount,
       c.src
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = c.item_sk
      AND p.p_discount_active = 'Y'
)
ORDER BY c.reference_date DESC,
         c.total_amount DESC
LIMIT 100
