SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_moy AS sales_month,
    s.s_store_name,
    cc.cc_division_name,
    ws.web_market_manager,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    CASE
        WHEN d_store_closed.d_year - d_cc_open.d_year >= 5 THEN 'Store closed >=5 years after CC open'
        ELSE 'Store closed <5 years after CC open'
    END AS store_cc_timing,
    CASE
        WHEN d_sales.d_year - d_web_close.d_year >= 10 THEN 'Web site >10 years old'
        ELSE 'Web site <=10 years old'
    END AS web_site_age_category
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sales.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'TX'
  AND cc.cc_country = 'United States'
GROUP BY
    d_sales.d_year,
    d_sales.d_moy,
    s.s_store_name,
    cc.cc_division_name,
    ws.web_market_manager,
    CASE
        WHEN d_store_closed.d_year - d_cc_open.d_year >= 5 THEN 'Store closed >=5 years after CC open'
        ELSE 'Store closed <5 years after CC open'
    END,
    CASE
        WHEN d_sales.d_year - d_web_close.d_year >= 10 THEN 'Web site >10 years old'
        ELSE 'Web site <=10 years old'
    END
ORDER BY total_net_profit DESC
LIMIT 100
