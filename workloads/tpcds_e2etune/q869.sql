SELECT
    s.s_store_name,
    cd.cd_gender,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(COALESCE(cr.cr_return_amount, 0)) AS net_profit_after_returns,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(*) AS total_sales_rows
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr
    ON ss.ss_cdemo_sk = cr.cr_returning_cdemo_sk
   AND ss.ss_hdemo_sk = cr.cr_returning_hdemo_sk
   AND ss.ss_addr_sk = cr.cr_returning_addr_sk
WHERE s.s_state = 'TX'
  AND p.p_start_date_sk BETWEEN 2451545 AND 2451910
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY s.s_store_name, cd.cd_gender, p.p_promo_name
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
