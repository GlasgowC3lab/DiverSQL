WITH promo_item AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_wholesale_cost,
        p.p_promo_sk,
        p.p_cost,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        p.p_channel_catalog,
        p.p_channel_dmail,
        p.p_channel_press,
        p.p_channel_event,
        p.p_response_target
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_start_date_sk BETWEEN 2450800 AND 2451100
)
SELECT
    pi.i_category,
    pi.i_brand,
    COUNT(DISTINCT pi.p_promo_sk) AS distinct_promotions,
    SUM(pi.p_cost) AS total_promo_cost,
    AVG(pi.i_current_price) AS avg_item_price,
    AVG(pi.i_wholesale_cost) AS avg_wholesale_cost,
    ROUND(AVG(pi.i_current_price - pi.i_wholesale_cost), 2) AS avg_gross_margin,
    SUM(CASE WHEN pi.p_channel_tv = 'Y' THEN pi.p_cost ELSE 0 END) AS tv_channel_cost,
    SUM(CASE WHEN pi.p_channel_email = 'Y' THEN pi.p_cost ELSE 0 END) AS email_channel_cost,
    (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'F') AS avg_female_purchase_estimate
FROM promo_item pi
GROUP BY pi.i_category, pi.i_brand
HAVING COUNT(DISTINCT pi.p_promo_sk) >= 3
ORDER BY total_promo_cost DESC
LIMIT 15
