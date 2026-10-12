SELECT
    d_cs.d_year AS sales_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_store_closed.d_year AS store_closed_year,
    cc.cc_market_manager,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    SUM(cs.cs_net_paid) AS catalog_total_net_paid,
    SUM(ss.ss_net_paid) AS store_total_net_paid,
    SUM(cs.cs_net_profit) AS catalog_total_net_profit,
    SUM(ss.ss_net_profit) AS store_total_net_profit,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_net_profit ELSE 0 END) AS catalog_profit_discounted,
    SUM(CASE WHEN ss.ss_ext_discount_amt > 0 THEN ss.ss_net_profit ELSE 0 END) AS store_profit_discounted,
    SUM(cs.cs_ext_tax) AS catalog_total_tax,
    SUM(ss.ss_ext_tax) AS store_total_tax,
    (SUM(cs.cs_net_profit) - SUM(ss.ss_net_profit)) AS profit_diff,
    CASE WHEN SUM(ss.ss_net_profit) = 0 THEN NULL ELSE ROUND(SUM(cs.cs_net_profit) / SUM(ss.ss_net_profit), 2) END AS profit_ratio
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_cs.d_year >= 2000
GROUP BY
    d_cs.d_year,
    d_cc_closed.d_year,
    d_store_closed.d_year,
    cc.cc_market_manager,
    s.s_state
HAVING
    SUM(cs.cs_net_profit) > 0
    AND SUM(ss.ss_net_profit) > 0
ORDER BY d_cs.d_year DESC, cc.cc_market_manager
LIMIT 100
