SELECT
    s.s_state AS store_state,
    i.i_category AS item_category,
    p.p_promo_name AS promo_name,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_coupon_amt) AS total_coupons
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE s.s_state IN ('AZ', 'CO')
  AND ca.ca_location_type = 'single family'
  AND i.i_category = 'Sports'
  AND p.p_channel_tv = 'Y'
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY s.s_state, i.i_category, p.p_promo_name
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
