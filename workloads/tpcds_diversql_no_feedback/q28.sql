WITH inv_agg AS (
       SELECT inv_item_sk,
              SUM(inv_quantity_on_hand) AS total_on_hand
       FROM inventory
       WHERE inv_quantity_on_hand > 300
         AND inv_date_sk = 2450962
       GROUP BY inv_item_sk
     ),
     wr_agg AS (
       SELECT wr_item_sk,
              SUM(wr_return_amt) AS total_return_amt,
              AVG(wr_return_amt) AS avg_return_amt,
              COUNT(*) AS return_cnt
       FROM web_returns
       WHERE wr_return_quantity > 0
         AND wr_returned_date_sk = 2450955
       GROUP BY wr_item_sk
     ),
     promo_agg AS (
       SELECT p_item_sk,
              SUM(p_cost) AS total_promo_cost,
              MIN(p_promo_name) AS any_promo_name
       FROM promotion
       WHERE p_channel_dmail = 'Y'
         AND p_discount_active = 'Y'
       GROUP BY p_item_sk
     )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    inv_agg.total_on_hand,
    wr_agg.total_return_amt,
    wr_agg.avg_return_amt,
    wr_agg.return_cnt,
    promo_agg.total_promo_cost,
    promo_agg.any_promo_name,
    CASE
        WHEN inv_agg.total_on_hand > (SELECT MAX(inv_quantity_on_hand) FROM inventory) THEN 'HighStock'
        ELSE 'NormalStock'
    END AS stock_category
FROM inv_agg
JOIN item i ON inv_agg.inv_item_sk = i.i_item_sk
JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk
JOIN promo_agg ON promo_agg.p_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
ORDER BY inv_agg.total_on_hand DESC, wr_agg.total_return_amt ASC
LIMIT 100
