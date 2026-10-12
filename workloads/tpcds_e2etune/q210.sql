WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_sold_date_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
),
item_sales AS (
    SELECT
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id,
        SUM(fs.ss_quantity) AS total_qty,
        SUM(fs.ss_net_profit) AS total_profit,
        SUM(fs.ss_ext_discount_amt) AS total_discount,
        AVG(fs.ss_ext_discount_amt) AS avg_discount,
        SUM(fs.ss_net_paid) AS total_sales
    FROM filtered_sales fs
    JOIN item i
      ON fs.ss_item_sk = i.i_item_sk
    WHERE i.i_class = 'decor'
      AND i.i_units = 'Bundle'
      AND i.i_size = 'large'
      AND i.i_category_id IN (5, 3)
    GROUP BY
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id
)
SELECT
    i_category,
    i_category_id,
    i_brand,
    total_qty,
    total_sales,
    total_profit,
    total_discount,
    avg_discount,
    total_profit / NULLIF(total_qty, 0) AS profit_per_unit,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM item_sales
ORDER BY total_profit DESC
LIMIT 10
