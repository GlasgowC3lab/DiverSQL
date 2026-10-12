SELECT
    s.s_state,
    d.d_year,
    i.i_brand,
    cd.cd_gender,
    hd.hd_vehicle_count,
    sum(ss.ss_net_paid) AS total_net_paid,
    avg(ss.ss_net_profit) AS avg_net_profit,
    count(DISTINCT ss.ss_ticket_number) AS distinct_orders,
    sum(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2000
  AND p.p_discount_active = 'Y'
GROUP BY s.s_state, d.d_year, i.i_brand, cd.cd_gender, hd.hd_vehicle_count
ORDER BY total_net_paid DESC
LIMIT 100
