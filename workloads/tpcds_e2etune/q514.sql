SELECT
    s.s_store_id,
    s.s_store_name,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
    SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_profit_after_returns
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN web_returns wr
    ON ca.ca_address_sk = wr.wr_refunded_addr_sk
WHERE s.s_state IN ('AZ', 'CO', 'PA')
  AND ca.ca_gmt_offset BETWEEN -7.00 AND -5.00
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY s.s_store_id, s.s_store_name, ca.ca_state
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 20
