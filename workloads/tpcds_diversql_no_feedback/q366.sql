WITH filtered AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        i.i_brand,
        i.i_class,
        i.i_manufact,
        i.i_current_price,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_account_credit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_brand = 'antiablecally'
      AND i.i_class = 'hockey'
      AND i.i_wholesale_cost BETWEEN 1.00 AND 10.00
      AND ss.ss_ext_wholesale_cost > 500
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity <= 2)
      AND (wr.wr_account_credit = 0.00 OR wr.wr_account_credit IS NULL)
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = ss.ss_item_sk
            AND wr2.wr_return_quantity > 10
      )
)
SELECT
    i_brand,
    i_class,
    i_manufact,
    COUNT(DISTINCT ss_ticket_number) AS unique_tickets,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    MIN(i_current_price) AS min_current_price,
    MAX(wr_return_amt) AS max_return_amount
FROM filtered
GROUP BY i_brand, i_class, i_manufact
ORDER BY total_sales DESC
LIMIT 100
