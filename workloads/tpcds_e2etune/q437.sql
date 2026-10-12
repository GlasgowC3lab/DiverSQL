WITH inv_agg AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk
),
promo_agg AS (
    SELECT p_item_sk, MAX(p_promo_name) AS promo_name
    FROM promotion
    GROUP BY p_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    pa.promo_name,
    ia.total_qty,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amt,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    RANK() OVER (ORDER BY (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) DESC) AS loss_rank
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN promo_agg pa ON i.i_item_sk = pa.p_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
  AND sr.sr_returned_date_sk BETWEEN 2451000 AND 2451100
  AND cr.cr_ship_mode_sk IN (4, 9, 16)
  AND i.i_category = 'Electronics'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY i.i_category, i.i_brand, pa.promo_name, ia.total_qty
HAVING (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 0
ORDER BY total_net_loss DESC
LIMIT 10
