WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_paid,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{2}')
      AND c.c_email_address LIKE '%@gmail.com'
)
SELECT
    i.i_category,
    cd.cd_gender,
    ib.ib_income_band_sk,
    d.d_year,
    SUM(fs.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT fs.ss_ticket_number) AS unique_tickets,
    MAX(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_full_name,
    MAX(SUBSTR(i.i_item_desc, 1, 15)) AS sample_short_desc,
    MAX(REGEXP_EXTRACT(i.i_product_name, '(\\d{3,})', 1)) AS sample_product_code
FROM filtered_sales fs
JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
JOIN customer c ON fs.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON fs.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY CUBE (i.i_category, cd.cd_gender, ib.ib_income_band_sk, d.d_year)
ORDER BY total_net_paid DESC
LIMIT 100
