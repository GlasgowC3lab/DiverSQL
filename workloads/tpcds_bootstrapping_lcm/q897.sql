SELECT
    s.s_store_id,
    d_ret.d_year,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    ROUND(AVG(cr.cr_net_loss), 2) AS avg_net_loss,
    SUM(CASE WHEN cr.cr_return_quantity > 2 THEN cr.cr_return_amount ELSE 0 END) AS multi_item_return_amount,
    SUM(CASE WHEN wp.wp_type = 'promo' THEN cr.cr_return_amount ELSE 0 END) AS promo_return_amount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MAX(d_access.d_month_seq) AS max_access_month_seq
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2002
  AND (hd_returning.hd_income_band_sk > 5 OR hd_refunded.hd_income_band_sk < 3)
GROUP BY s.s_store_id, d_ret.d_year, hd_returning.hd_buy_potential
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
