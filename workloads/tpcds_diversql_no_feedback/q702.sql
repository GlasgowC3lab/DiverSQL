WITH cr_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_refunded_addr_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_tax > 5.00
      AND cr_warehouse_sk IN (6, 9)
    GROUP BY cr_returned_date_sk, cr_item_sk, cr_refunded_addr_sk
)
SELECT
    d.d_year,
    i.i_category,
    s.s_store_name,
    SUM(cr_agg.sum_return_amount) AS total_return_amount,
    AVG(cr_agg.avg_return_tax) AS overall_avg_tax,
    SUM(cr_agg.cnt_returns) AS total_returns,
    MIN(cr_agg.min_return_amount) AS min_return_amount,
    MAX(cr_agg.max_return_amount) AS max_return_amount
FROM cr_agg
JOIN tpcds.date_dim d
    ON cr_agg.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.item i
    ON cr_agg.cr_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca
    ON cr_agg.cr_refunded_addr_sk = ca.ca_address_sk
JOIN tpcds.store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE i.i_color = 'olive'
  AND d.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY CUBE (d.d_year, i.i_category, s.s_store_name)
ORDER BY total_return_amount DESC
LIMIT 100
