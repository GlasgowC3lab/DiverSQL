WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_customer_sk,
        s.s_store_name,
        p.p_promo_name,
        t.t_hour,
        concat(s.s_store_name, ' - ', p.p_promo_name) AS store_promo,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(s.s_store_name, '^A.*')               -- store names starting with "A"
      AND p.p_promo_name LIKE '%Discount%'                -- promotion names containing the word Discount
      AND substr(p.p_promo_name, 1, 3) = 'SPR'            -- first three chars equal "SPR"
)
SELECT
    f.s_store_name,
    COUNT(DISTINCT f.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT f.ss_customer_sk)   AS distinct_customers,
    SUM(DISTINCT f.ss_net_paid)        AS sum_distinct_net_paid,
    AVG(f.ss_quantity)                 AS avg_quantity,
    MAX(
        CASE
            WHEN f.ss_customer_sk = (
                SELECT max(c_customer_sk)
                FROM tpcds.customer
                WHERE c_email_address LIKE '%@gmail.com'
            ) THEN 'TopGmailCustomer'
            ELSE 'Other'
        END
    ) AS customer_group,
    MAX(f.store_promo) AS example_concatenation,
    MAX(f.promo_code)  AS extracted_promo_code
FROM filtered_sales f
GROUP BY f.s_store_name
HAVING COUNT(DISTINCT f.ss_ticket_number) > 10
ORDER BY sum_distinct_net_paid DESC
LIMIT 100
