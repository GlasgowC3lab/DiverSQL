WITH brand_inventory AS (
    SELECT i.i_brand AS brand,
           SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_brand
),
sales_agg AS (
    SELECT i.i_brand AS brand,
           cd.cd_education_status AS education_status,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND i.i_current_price > 20
      AND cd.cd_education_status IN ('College', '4 yr Degree')
    GROUP BY i.i_brand, cd.cd_education_status
)
SELECT s.brand,
       s.education_status,
       s.total_net_profit,
       s.total_quantity,
       s.avg_discount,
       s.distinct_customers,
       b.total_inventory_on_hand,
       RANK() OVER (PARTITION BY s.education_status ORDER BY s.total_net_profit DESC) AS brand_rank
FROM sales_agg s
JOIN brand_inventory b ON s.brand = b.brand
WHERE s.total_net_profit > 10000
ORDER BY s.education_status, brand_rank
LIMIT 20
