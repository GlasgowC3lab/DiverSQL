WITH filtered_sales AS (
    SELECT ss.*
    FROM store_sales ss
    WHERE ss.ss_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE regexp_like(c.c_email_address, '@gmail\\.com$')
    )
)
SELECT
    w.w_city || ', ' || w.w_state AS location,
    regexp_extract(w.w_zip, '^(\\d{3})', 1) AS zip_prefix,
    d.d_year,
    d.d_month_seq,
    SUM(fs.ss_net_profit) AS total_net_profit,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    CASE
        WHEN d.d_holiday = 'Y' THEN SUM(fs.ss_net_profit) * 1.10
        ELSE SUM(fs.ss_net_profit)
    END AS holiday_adjusted_profit,
    COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets,
    substring(c.c_last_name, 1, 1) AS last_initial
FROM filtered_sales fs
JOIN date_dim d
    ON fs.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_suite_number LIKE 'Suite %'
  AND regexp_like(w.w_street_name, 'Street')
GROUP BY
    w.w_city,
    w.w_state,
    w.w_zip,
    d.d_year,
    d.d_month_seq,
    d.d_holiday,
    c.c_last_name
ORDER BY total_net_profit DESC
LIMIT 100
