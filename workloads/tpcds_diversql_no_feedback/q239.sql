WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_return_quantity >= 5
      AND cr_return_ship_cost > 100.00
      AND cr_returning_hdemo_sk IN (
            SELECT DISTINCT cr_returning_hdemo_sk
            FROM catalog_returns
            WHERE cr_return_quantity > 50
      )
)
SELECT
    d.d_year,
    d.d_quarter_name,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_ship_cost) AS avg_ship_cost,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
JOIN date_dim d
  ON fr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_quarter_name = '1900Q1'
  AND d.d_current_quarter = 'Y'
GROUP BY d.d_year, d.d_quarter_name
ORDER BY total_return_amount DESC
LIMIT 100
