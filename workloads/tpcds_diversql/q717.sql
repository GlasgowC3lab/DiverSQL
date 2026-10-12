WITH item_prices AS (
    SELECT
        i_item_sk,
        i_item_id,
        ARRAY[CAST(i_current_price AS DOUBLE), CAST(i_wholesale_cost AS DOUBLE)] AS price_vals
    FROM item
),
returns_agg AS (
    SELECT
        item_sk,
        date_sk,
        SUM(return_amt) AS total_return_amt,
        SUM(return_quantity) AS total_quantity
    FROM (
        SELECT
            sr_item_sk AS item_sk,
            sr_returned_date_sk AS date_sk,
            sr_return_amt AS return_amt,
            sr_return_quantity AS return_quantity
        FROM store_returns
        UNION ALL
        SELECT
            cr_item_sk AS item_sk,
            cr_returned_date_sk AS date_sk,
            cr_return_amount AS return_amt,
            cr_return_quantity AS return_quantity
        FROM catalog_returns
        UNION ALL
        SELECT
            wr_item_sk AS item_sk,
            wr_returned_date_sk AS date_sk,
            wr_return_amt AS return_amt,
            wr_return_quantity AS return_quantity
        FROM web_returns
    ) r
    GROUP BY item_sk, date_sk
)
SELECT
    i.i_item_id,
    d.d_year,
    CASE WHEN p.price_idx = 1 THEN 'current_price' ELSE 'wholesale_cost' END AS price_type,
    SUM(ra.total_return_amt) AS total_return_amount,
    SUM(ra.total_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM returns_agg ra
JOIN date_dim d ON ra.date_sk = d.d_date_sk
JOIN item i ON ra.item_sk = i.i_item_sk
JOIN item_prices ip ON i.i_item_sk = ip.i_item_sk
CROSS JOIN UNNEST(ip.price_vals) WITH ORDINALITY AS p(price, price_idx)
JOIN catalog_returns cr
  ON cr.cr_item_sk = ra.item_sk
 AND cr.cr_returned_date_sk = ra.date_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ra.item_sk
 AND wr.wr_returned_date_sk = ra.date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
WHERE EXISTS (
    SELECT 1 FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
      AND wp2.wp_image_count > 5
)
GROUP BY GROUPING SETS (
    (i.i_item_id, d.d_year, p.price_idx),
    (i.i_item_id, p.price_idx)
)
HAVING SUM(ra.total_return_amt) > 1000
ORDER BY total_return_amount DESC, i.i_item_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
