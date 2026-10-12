WITH filtered_customers AS (
    SELECT c_customer_sk, c_birth_country
    FROM customer
    WHERE c_birth_year BETWEEN 1950 AND 1990
      AND c_birth_country IN ('TURKMENISTAN', 'IRELAND', 'NAURU')
),
filtered_returns AS (
    SELECT sr_customer_sk, sr_net_loss, sr_return_amt, sr_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND sr_return_amt > 50
),
filtered_pages AS (
    SELECT wp_customer_sk, wp_type, wp_image_count
    FROM web_page
    WHERE wp_image_count >= 5
),
aggregated AS (
    SELECT
        fc.c_birth_country,
        fp.wp_type,
        COUNT(DISTINCT fc.c_customer_sk) AS distinct_customers,
        SUM(fr.sr_net_loss) AS total_net_loss,
        AVG(fr.sr_return_amt) AS avg_return_amount,
        SUM(fr.sr_return_quantity) AS total_return_qty,
        AVG(fp.wp_image_count) AS avg_image_count
    FROM filtered_customers fc
    JOIN filtered_returns fr ON fc.c_customer_sk = fr.sr_customer_sk
    JOIN filtered_pages fp ON fc.c_customer_sk = fp.wp_customer_sk
    GROUP BY fc.c_birth_country, fp.wp_type
    HAVING SUM(fr.sr_net_loss) > 1000
)
SELECT
    a.c_birth_country,
    a.wp_type,
    a.distinct_customers,
    a.total_net_loss,
    a.avg_return_amount,
    a.total_return_qty,
    a.avg_image_count,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 20
