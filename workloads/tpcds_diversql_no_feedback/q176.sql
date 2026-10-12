WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        s.s_city,
        s.s_state,
        ca.ca_street_name,
        td.t_hour
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(s.s_city, '^.*York.*$')
      AND ca.ca_street_name LIKE '%Oak%'
)
SELECT
    fs.s_city,
    fs.s_state,
    COUNT(*) AS sales_cnt,
    SUM(fs.ss_net_paid) AS total_net_paid,
    AVG(fs.ss_quantity) AS avg_quantity,
    CONCAT('City-', fs.s_city) AS city_label,
    SUBSTRING(fs.ca_street_name, 1, 5) AS street_prefix,
    REGEXP_EXTRACT(fs.ca_street_name, '(\\w+)$') AS street_suffix
FROM filtered_sales fs
WHERE fs.ss_ticket_number NOT IN (
    SELECT sr_ticket_number FROM store_returns
)
GROUP BY
    fs.s_city,
    fs.s_state,
    fs.ca_street_name
ORDER BY total_net_paid DESC
LIMIT 100
