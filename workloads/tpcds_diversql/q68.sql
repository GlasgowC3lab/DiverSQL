/*
Goal: Identify the top‑selling items by state, segmented by income band, while excluding items that have experienced a high net loss on web returns. The query joins all six selected TPC‑DS tables, applies multiple filter predicates, uses a CASE expression for income grouping, ranks states by sales, and limits the result to the top 100 rows.
*/
WITH sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_quantity >= 2
      AND ss.ss_net_paid > 100
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
      AND ss.ss_ext_sales_price > 50
      AND ss.ss_net_profit > 0
),
high_loss_returns AS (
    SELECT wr.wr_item_sk
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
    HAVING MAX(wr.wr_net_loss) > 500
)
SELECT
    ca.ca_state,
    ib.ib_upper_bound,
    i.i_category,
    i.i_brand,
    SUM(sf.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT sf.ss_customer_sk) AS unique_customers,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(sf.ss_ext_sales_price) DESC) AS sales_rank_state,
    CASE
        WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_upper_bound >= 100000 THEN 'Upper Mid Income'
        ELSE 'Lower Income'
    END AS income_group
FROM sales_filtered sf
JOIN item i
    ON sf.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON sf.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON sf.ss_addr_sk = ca.ca_address_sk
WHERE i.i_item_sk NOT IN (SELECT wr_item_sk FROM high_loss_returns)
  AND ca.ca_country = 'United States'
  AND ib.ib_lower_bound >= 20000
  AND i.i_class IN ('sports-apparel', 'furniture')
  AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY
    ca.ca_state,
    ib.ib_upper_bound,
    i.i_category,
    i.i_brand,
    CASE
        WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_upper_bound >= 100000 THEN 'Upper Mid Income'
        ELSE 'Lower Income'
    END
ORDER BY total_sales DESC
LIMIT 100
