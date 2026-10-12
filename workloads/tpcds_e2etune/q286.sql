WITH item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_brand, i.i_product_name
),
promo_summary AS (
    SELECT
        p.p_item_sk,
        COUNT(*) FILTER (WHERE p.p_discount_active = 'Y') AS active_promo_cnt,
        COUNT(*) AS total_promo_cnt
    FROM promotion p
    GROUP BY p.p_item_sk
)
SELECT
    r.r_reason_desc,
    ii.i_category,
    ii.i_brand,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    ii.total_on_hand,
    COALESCE(ps.active_promo_cnt, 0) AS active_promos,
    COALESCE(ps.total_promo_cnt, 0) AS total_promos
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN item_inventory ii ON i.i_item_sk = ii.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN promo_summary ps ON i.i_item_sk = ps.p_item_sk
JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
  AND ca_ret.ca_gmt_offset = -6.00
  AND i.i_current_price > 20
GROUP BY r.r_reason_desc, ii.i_category, ii.i_brand, ii.total_on_hand, ps.active_promo_cnt, ps.total_promo_cnt
HAVING SUM(wr.wr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 100
