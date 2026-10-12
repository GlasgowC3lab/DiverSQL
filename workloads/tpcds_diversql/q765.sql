WITH sales_filtered AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_net_paid_inc_tax,
    ss.ss_ext_sales_price,
    d.d_year,
    d.d_month_seq,
    d.d_dow
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND d.d_month_seq BETWEEN 120 AND 130
    AND d.d_dow IN (1, 2, 3)
    AND ss.ss_quantity > 1
    AND ss.ss_net_paid_inc_tax > 500
    AND ss.ss_ext_sales_price > 1000
),
web_filtered AS (
  SELECT
    wp.wp_web_page_sk,
    wp.wp_creation_date_sk,
    wp.wp_image_count,
    wp.wp_type,
    d.d_year AS wp_year,
    d.d_month_seq AS wp_month_seq,
    d.d_dow AS wp_dow
  FROM web_page wp
  JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND d.d_month_seq BETWEEN 120 AND 130
    AND d.d_dow IN (1, 2, 3)
    AND wp.wp_image_count >= 3
    AND wp.wp_type = 'content'
),
ticket_numbers_all AS (
  SELECT ss_ticket_number FROM sales_filtered
),
ticket_numbers_excluded AS (
  SELECT ss_ticket_number FROM sales_filtered WHERE ss_quantity < 5
),
customer_set_a AS (
  SELECT ss_customer_sk FROM sales_filtered WHERE ss_net_paid_inc_tax > 1000
),
customer_set_b AS (
  SELECT ss_customer_sk FROM sales_filtered WHERE ss_quantity >= 10
)
SELECT
  sf.ss_ticket_number,
  sf.ss_customer_sk,
  sf.ss_net_paid_inc_tax,
  wf.wp_web_page_sk,
  wf.wp_image_count,
  RANK() OVER (PARTITION BY sf.d_year ORDER BY sf.ss_net_paid_inc_tax DESC) AS yearly_rank,
  (
    SELECT SUM(ss2.ss_net_paid_inc_tax)
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = sf.ss_customer_sk
  ) AS cust_total_paid_inc_tax
FROM sales_filtered sf
JOIN web_filtered wf ON sf.d_year = wf.wp_year AND sf.d_month_seq = wf.wp_month_seq
WHERE sf.ss_customer_sk IN (
        SELECT ss_customer_sk FROM customer_set_a
        INTERSECT
        SELECT ss_customer_sk FROM customer_set_b
      )
  AND sf.ss_ticket_number IN (
        SELECT ss_ticket_number FROM ticket_numbers_all
        EXCEPT
        SELECT ss_ticket_number FROM ticket_numbers_excluded
      )
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = sf.ss_customer_sk
          AND wp2.wp_image_count > 0
      )
UNION
SELECT
  sf.ss_ticket_number,
  sf.ss_customer_sk,
  sf.ss_net_paid_inc_tax,
  wf.wp_web_page_sk,
  wf.wp_image_count,
  DENSE_RANK() OVER (PARTITION BY sf.d_year ORDER BY sf.ss_net_paid_inc_tax DESC) AS yearly_rank,
  (
    SELECT SUM(ss2.ss_net_paid_inc_tax)
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = sf.ss_customer_sk
  ) AS cust_total_paid_inc_tax
FROM sales_filtered sf
JOIN web_filtered wf ON sf.ss_sold_date_sk = wf.wp_creation_date_sk
WHERE sf.ss_customer_sk IN (
        SELECT ss_customer_sk FROM customer_set_a
        INTERSECT
        SELECT ss_customer_sk FROM customer_set_b
      )
  AND sf.ss_ticket_number IN (
        SELECT ss_ticket_number FROM ticket_numbers_all
        EXCEPT
        SELECT ss_ticket_number FROM ticket_numbers_excluded
      )
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = sf.ss_customer_sk
          AND wp2.wp_image_count > 0
      )
ORDER BY yearly_rank, ss_ticket_number
LIMIT 100
