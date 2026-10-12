WITH item_net_return_stats AS (
    SELECT
        i.i_item_sk,
        AVG(sr.sr_return_amt - sr.sr_return_tax - sr.sr_fee) AS avg_net_return
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    d_ret.d_date AS return_date,
    d_closed.d_date AS store_closed_date,
    d_access.d_date AS page_access_date,
    i.i_product_name,
    i.i_category,
    i.i_current_price,
    i.i_wholesale_cost,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    sr.sr_return_tax,
    sr.sr_fee,
    wp.wp_url,
    wp.wp_type,
    (sr.sr_return_amt - sr.sr_return_tax - sr.sr_fee) AS net_return_amount,
    (i.i_current_price - i.i_wholesale_cost) AS price_margin,
    stats.avg_net_return,
    SUM(sr.sr_return_amt) OVER (PARTITION BY s.s_store_sk, d_ret.d_date) AS store_day_total_return,
    RANK() OVER (PARTITION BY d_ret.d_date ORDER BY (sr.sr_return_amt - sr.sr_return_tax - sr.sr_fee) DESC) AS net_return_rank
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN item_net_return_stats stats ON i.i_item_sk = stats.i_item_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
  AND i.i_category = 'Electronics'
  AND (sr.sr_return_amt - sr.sr_return_tax - sr.sr_fee) > stats.avg_net_return
ORDER BY d_ret.d_date DESC, net_return_rank
LIMIT 100
