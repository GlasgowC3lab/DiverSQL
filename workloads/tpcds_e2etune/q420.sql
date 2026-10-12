WITH quarter_page_counts AS (
    SELECT
        DATE_TRUNC('quarter', d.d_date) AS quarter_start,
        SUM(wp.wp_link_count) AS total_links
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_quarter_name = '1900Q2'
      AND d.d_weekend = 'Y'
    GROUP BY DATE_TRUNC('quarter', d.d_date)
)
SELECT
    s.s_division_name,
    s.s_store_name,
    DATE_TRUNC('quarter', d.d_date) AS quarter_start,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_quantity) AS total_units,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit / NULLIF(ss.ss_net_paid, 0)) AS profit_margin,
    MAX(qpc.total_links) AS quarter_page_links
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN quarter_page_counts qpc ON DATE_TRUNC('quarter', d.d_date) = qpc.quarter_start
WHERE d.d_quarter_name = '1900Q2'
  AND d.d_weekend = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY s.s_division_name, s.s_store_name, DATE_TRUNC('quarter', d.d_date)
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
