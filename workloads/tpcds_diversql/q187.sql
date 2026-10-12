WITH combined_returns AS (
    SELECT
        c.c_customer_sk AS customer_id,
        i.i_product_name AS product_name,
        regexp_extract(i.i_product_name, '([A-Za-z]+)', 1) AS product_alpha,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss,
        substring(c.c_first_name, 1, 1) || substring(c.c_last_name, 1, 1) AS first_letter_name
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_product_name, 'ought')
      AND c.c_email_address LIKE '%@example.com'
    GROUP BY c.c_customer_sk, i.i_product_name, c.c_first_name, c.c_last_name

    UNION DISTINCT

    SELECT
        c.c_customer_sk AS customer_id,
        i.i_product_name AS product_name,
        regexp_extract(i.i_product_name, '([A-Za-z]+)', 1) AS product_alpha,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        substring(c.c_first_name, 1, 1) || substring(c.c_last_name, 1, 1) AS first_letter_name
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_product_name, 'ought')
      AND c.c_email_address LIKE '%@example.com'
    GROUP BY c.c_customer_sk, i.i_product_name, c.c_first_name, c.c_last_name
)
SELECT
    customer_id,
    product_name,
    product_alpha,
    total_return_qty,
    total_net_loss,
    first_letter_name
FROM combined_returns
ORDER BY total_net_loss DESC
LIMIT 100
