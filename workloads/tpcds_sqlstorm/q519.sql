SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    i.i_brand,
    cd.cd_gender,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_adj,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(ss.ss_quantity) AS avg_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
WHERE d.d_year = 2000
  AND s.s_state = 'CA'
  AND i.i_category = 'Sports'
  AND t.t_hour BETWEEN 9 AND 17
  AND c.c_preferred_cust_flag = 'Y'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = 'HIGH'
GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_brand, cd.cd_gender, p.p_promo_name
ORDER BY net_profit_adj DESC
LIMIT 100
