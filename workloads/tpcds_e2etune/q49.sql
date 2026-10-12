WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ss_item_sk, ss_sold_date_sk
),
returns_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_fee) AS total_fee,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY cr_item_sk, cr_returned_date_sk
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    s.ss_item_sk AS item_sk,
    s.ss_sold_date_sk AS date_sk,
    s.total_sales,
    r.total_return_amount,
    (r.total_return_amount / NULLIF(s.total_sales, 0)) AS return_to_sales_ratio,
    (s.total_profit - r.total_net_loss) AS net_profit_after_returns,
    s.total_quantity,
    r.total_return_quantity,
    RANK() OVER (PARTITION BY s.ss_item_sk ORDER BY (r.total_return_amount / NULLIF(s.total_sales, 0)) DESC) AS return_rank
FROM sales_agg s
JOIN returns_agg r
  ON s.ss_item_sk = r.cr_item_sk
 AND s.ss_sold_date_sk = r.cr_returned_date_sk
WHERE s.total_sales > 0
  AND r.total_return_amount > 0
ORDER BY return_to_sales_ratio DESC
LIMIT 100
