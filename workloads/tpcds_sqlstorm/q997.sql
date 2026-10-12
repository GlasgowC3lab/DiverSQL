WITH
sales_union AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_sold_date_sk AS date_sk,
           cs_net_profit AS net_profit,
           cs_ext_sales_price AS sales_amount,
           cs_quantity AS quantity,
           cs_item_sk AS item_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS customer_sk,
           ss_sold_date_sk AS date_sk,
           ss_net_profit AS net_profit,
           ss_ext_sales_price AS sales_amount,
           ss_quantity AS quantity,
           ss_item_sk AS item_sk
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_sold_date_sk AS date_sk,
           ws_net_profit AS net_profit,
           ws_ext_sales_price AS sales_amount,
           ws_quantity AS quantity,
           ws_item_sk AS item_sk
    FROM web_sales
),
returns_union AS (
    SELECT cr_returning_customer_sk AS customer_sk,
           cr_returned_date_sk AS date_sk,
           cr_net_loss AS net_loss
    FROM catalog_returns
    UNION ALL
    SELECT sr_customer_sk AS customer_sk,
           sr_returned_date_sk AS date_sk,
           sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT wr_returning_customer_sk AS customer_sk,
           wr_returned_date_sk AS date_sk,
           wr_net_loss AS net_loss
    FROM web_returns
),
sales_agg AS (
    SELECT su.customer_sk,
           COALESCE(SUM(su.net_profit), 0) AS total_sales_profit,
           COALESCE(SUM(su.sales_amount), 0) AS total_sales_amount,
           COALESCE(SUM(su.quantity), 0) AS total_quantity,
           COUNT(DISTINCT su.item_sk) AS distinct_items_sold,
           MIN(dd.d_date) AS first_sale_date,
           MAX(dd.d_date) AS last_sale_date
    FROM sales_union su
    LEFT JOIN date_dim dd ON su.date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2001 AND 2002
    GROUP BY su.customer_sk
),
returns_agg AS (
    SELECT ru.customer_sk,
           COALESCE(SUM(ru.net_loss), 0) AS total_returns_loss,
           MIN(dd.d_date) AS first_return_date,
           MAX(dd.d_date) AS last_return_date
    FROM returns_union ru
    LEFT JOIN date_dim dd ON ru.date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2001 AND 2002
    GROUP BY ru.customer_sk
),
full_agg AS (
    SELECT COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
           s.total_sales_profit,
           s.total_sales_amount,
           s.total_quantity,
           s.distinct_items_sold,
           s.first_sale_date,
           s.last_sale_date,
           r.total_returns_loss,
           r.first_return_date,
           r.last_return_date
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r ON s.customer_sk = r.customer_sk
)
SELECT
    c.c_customer_sk,
    UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_upper,
    COALESCE(c.c_email_address, 'UNKNOWN@UNKNOWN.COM') AS email_address,
    COALESCE(c.c_birth_country, 'UNKNOWN') AS birth_country,
    fa.total_sales_profit,
    fa.total_returns_loss,
    (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) AS net_total_profit,
    ROUND(
        (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) /
        NULLIF(SUM(fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) OVER (), 0) *
        100, 2) AS percent_of_total_profit,
    ROW_NUMBER() OVER (ORDER BY (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) DESC) AS profit_rank,
    SUM(fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) OVER (
        ORDER BY (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_profit,
    CASE
        WHEN (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) > 
            (SUM(fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) OVER ()) * 0.01
        THEN 1 ELSE 0 END AS high_value_flag,
    fa.distinct_items_sold,
    fa.total_quantity,
    CAST(fa.first_sale_date AS VARCHAR) AS first_sale_date,
    CAST(fa.last_sale_date AS VARCHAR) AS last_sale_date,
    CAST(fa.first_return_date AS VARCHAR) AS first_return_date,
    CAST(fa.last_return_date AS VARCHAR) AS last_return_date,
    (
        SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk
    ) +
    (
        SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = c.c_customer_sk
    ) +
    (
        SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk
    ) AS total_return_transactions,
    CASE
        WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
        WHEN c.c_preferred_cust_flag = 'N' THEN 'Standard'
        ELSE 'Unknown'
    END AS customer_preference_status,
    COALESCE(c.c_last_review_date, -1) AS last_review_date_sk
FROM full_agg fa
LEFT JOIN customer c ON fa.customer_sk = c.c_customer_sk
WHERE (fa.total_sales_profit - COALESCE(fa.total_returns_loss, 0)) > 0
  AND (c.c_birth_country = 'United States' OR c.c_birth_country IS NULL)
ORDER BY net_total_profit DESC
LIMIT 100
