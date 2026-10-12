WITH flags AS (
    SELECT 1 AS flag UNION ALL SELECT 2
)
SELECT
    s.s_store_name,
    td1.t_hour,
    hd.hd_buy_potential,
    f.flag,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_refunded_cash) AS total_refunds,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM store_sales ss
JOIN time_dim td1
    ON ss.ss_sold_time_sk = td1.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN time_dim td2
    ON sr.sr_return_time_sk = td2.t_time_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
CROSS JOIN flags f
GROUP BY
    s.s_store_name,
    td1.t_hour,
    hd.hd_buy_potential,
    f.flag,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
ORDER BY total_store_sales DESC
LIMIT 100
